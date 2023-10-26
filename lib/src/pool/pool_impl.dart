import 'dart:async';

import 'package:collection/collection.dart';
import 'package:pool/pool.dart' as pool;

import '../../postgres.dart';
import '../v3/connection.dart';

EndpointSelector roundRobinSelector(List<Endpoint> endpoints) {
  int nextIndex = 0;
  return (EndpointSelectorContext context) {
    final endpoint = endpoints[nextIndex];
    nextIndex = (nextIndex + 1) % endpoints.length;
    return EndpointSelection(endpoint: endpoint);
  };
}

class PoolImplementation<L> implements Pool<L> {
  final EndpointSelector<L> _selector;
  final SessionSettings? sessionSettings;
  final PoolSettings? poolSettings;

  final pool.Pool _semaphore;
  final _connections = <_PoolConnection>[];

  PoolImplementation(this._selector, this.sessionSettings, this.poolSettings)
      : _semaphore = pool.Pool(
          poolSettings?.maxConnectionCount ?? 1,
          timeout:
              sessionSettings?.connectTimeout ?? const Duration(seconds: 15),
        );

  @override
  Future<void> close() async {
    await _semaphore.close();

    // Connections are closed when they are returned to the pool if it's closed.
    // We still need to close statements that are currently unused.
    for (final connection in [..._connections]) {
      if (!connection._isInUse) {
        await connection._dispose();
      }
    }
  }

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) {
    return withConnection((connection) => connection.execute(
          query,
          parameters: parameters,
          ignoreRows: ignoreRows,
          queryMode: queryMode,
          timeout: timeout,
        ));
  }

  @override
  Future<Statement> prepare(Object query) async {
    final statementCompleter = Completer<Statement>.sync();

    unawaited(withConnection((connection) async {
      _PoolStatement? poolStatement;

      try {
        final statement = await connection.prepare(query);
        poolStatement = _PoolStatement(statement);
      } on Object catch (e, s) {
        // Could not prepare the statement, inform the caller and stop occupying
        // the connection.
        statementCompleter.completeError(e, s);
        return;
      }

      // Otherwise, make the future returned by prepare complete with the
      // statement.
      statementCompleter.complete(poolStatement);

      // And keep this connection reserved until the statement has been disposed.
      return poolStatement._disposed.future;
    }));

    return statementCompleter.future;
  }

  @override
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    L? locality,
  }) {
    return withConnection(
      (connection) => connection.run(fn),
      locality: locality,
    );
  }

  @override
  Future<R> runTx<R>(
    Future<R> Function(Session session) fn, {
    TransactionMode? transactionMode,
    L? locality,
  }) {
    return withConnection(
      (connection) => connection.runTx(
        fn,
        transactionMode: transactionMode,
      ),
      locality: locality,
    );
  }

  @override
  Future<R> withConnection<R>(
    Future<R> Function(Connection connection) fn, {
    SessionSettings? sessionSettings,
    L? locality,
  }) async {
    final resource = await _semaphore.request();

    _PoolConnection? connection;
    bool reuse = true;
    try {
      final context = EndpointSelectorContext(
        locality: locality,
      );
      final selection = await _selector(context);

      // Find an existing connection that is currently unused, or open another
      // one.
      connection = _connections
          .firstWhereOrNull((c) => c._mayReuse(endpoint: selection.endpoint));
      if (connection == null) {
        connection ??= _PoolConnection(
          this,
          selection.endpoint,
          await PgConnectionImplementation.connect(
            selection.endpoint,
            sessionSettings: sessionSettings ?? this.sessionSettings,
          ),
        );
        _connections.add(connection);
      }

      connection._isInUse = true;
      try {
        return await fn(connection);
      } catch (_) {
        reuse = false;
        rethrow;
      }
    } finally {
      resource.release();

      // If the pool has been closed, this connection needs to be closed as
      // well.
      if (_semaphore.isClosed || !reuse) {
        await connection?._dispose();
      } else {
        // Allow the connection to be re-used later.
        connection?._isInUse = false;
      }
    }
  }
}

/// An opened [Connection] we're able to use in [Pool.withConnection].
class _PoolConnection implements Connection {
  final PoolImplementation _pool;
  final Endpoint _endpoint;
  final PgConnectionImplementation _connection;
  bool _isInUse = false;

  _PoolConnection(this._pool, this._endpoint, this._connection);

  bool _mayReuse({
    required Endpoint endpoint,
  }) {
    if (_isInUse) return false;
    if (endpoint != _endpoint) return false;
    return true;
  }

  Future<void> _dispose() async {
    _pool._connections.remove(this);
    await _connection.close();
  }

  @override
  Channels get channels {
    throw UnsupportedError(
      'Channels are not supported in pools because they would require keeping '
      'the connection open even after `withConnection` has returned.',
    );
  }

  @override
  Future<void> close() async {
    // Don't forward the close call, the underlying connection should be re-used
    // when another pool connection is requested.
  }

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) {
    return _connection.execute(
      query,
      parameters: parameters,
      ignoreRows: ignoreRows,
      queryMode: queryMode,
      timeout: timeout,
    );
  }

  @override
  Future<Statement> prepare(Object query) {
    return _connection.prepare(query);
  }

  @override
  Future<R> run<R>(Future<R> Function(Session session) fn) {
    return _connection.run(fn);
  }

  @override
  Future<R> runTx<R>(
    Future<R> Function(Session session) fn, {
    TransactionMode? transactionMode,
  }) {
    return _connection.runTx(
      fn,
      transactionMode: transactionMode,
    );
  }
}

class _PoolStatement implements Statement {
  final Completer<void> _disposed = Completer();
  final Statement _underlying;

  _PoolStatement(this._underlying);

  @override
  ResultStream bind(Object? parameters) => _underlying.bind(parameters);

  @override
  Future<void> dispose() async {
    _disposed.complete();
    await _underlying.dispose();
  }

  @override
  Future<Result> run(
    Object? parameters, {
    Duration? timeout,
  }) {
    return _underlying.run(parameters, timeout: timeout);
  }
}
