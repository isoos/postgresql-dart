import 'dart:async';

import 'package:collection/collection.dart';
import 'package:pool/pool.dart' as pool;
import 'package:postgres/src/v3/resolved_settings.dart';

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
  final ResolvedPoolSettings settings;

  final _connections = <_PoolConnection>[];
  late final _maxConnectionCount = settings.maxConnectionCount;
  late final _semaphore = pool.Pool(
    _maxConnectionCount,
    timeout: settings.connectTimeout,
  );

  PoolImplementation(this._selector, PoolSettings? settings)
      : settings = ResolvedPoolSettings(settings);

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
    SessionSettings? settings,
    L? locality,
  }) {
    return withConnection(
      (connection) => connection.run(fn, settings: settings),
      locality: locality,
    );
  }

  @override
  Future<R> runTx<R>(
    Future<R> Function(Session session) fn, {
    TransactionSettings? settings,
    L? locality,
  }) {
    return withConnection(
      (connection) => connection.runTx(
        fn,
        settings: settings,
      ),
      locality: locality,
    );
  }

  @override
  Future<R> withConnection<R>(
    Future<R> Function(Connection connection) fn, {
    ConnectionSettings? connectionSettings,
    L? locality,
  }) async {
    final resource = await _semaphore.request();

    _PoolConnection? connection;
    bool reuse = true;
    final sw = Stopwatch();
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
            connectionSettings:
                ResolvedConnectionSettings(connectionSettings, this.settings),
          ),
        );
        _connections.add(connection);
      }

      connection._isInUse = true;
      sw.start();
      try {
        return await fn(connection);
      } catch (_) {
        reuse = false;
        rethrow;
      }
    } finally {
      resource.release();
      sw.stop();
      connection?._elapsedInUse += sw.elapsed;

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
  final _opened = DateTime.now();
  final PoolImplementation _pool;
  final Endpoint _endpoint;
  final PgConnectionImplementation _connection;
  Duration _elapsedInUse = Duration.zero;
  bool _isInUse = false;
  int _queryCount = 0;

  _PoolConnection(this._pool, this._endpoint, this._connection);

  bool _mayReuse({
    required Endpoint endpoint,
  }) {
    if (_isInUse || endpoint != _endpoint || _isExpired()) {
      return false;
    }
    return true;
  }

  bool _isExpired() {
    final age = DateTime.now().difference(_opened);
    if (age > _pool.settings.maxConnectionAge) {
      return true;
    }
    if (_elapsedInUse > _pool.settings.maxSessionUse) {
      return true;
    }
    if (_queryCount > _pool.settings.maxQueryCount) {
      return true;
    }
    return false;
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
    _queryCount++;
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
    // TODO: increment query count on statement runs
    return _connection.prepare(query);
  }

  @override
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    SessionSettings? settings,
  }) {
    // TODO: increment query count on session callbacks
    return _connection.run(fn, settings: settings);
  }

  @override
  Future<R> runTx<R>(
    Future<R> Function(Session session) fn, {
    TransactionSettings? settings,
  }) {
    // TODO: increment query count on session callbacks
    return _connection.runTx(
      fn,
      settings: settings,
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
