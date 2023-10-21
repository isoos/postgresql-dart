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

  final pool.Pool _pool;
  final List<_OpenedConnection> _openConnections = [];

  PoolImplementation(this._selector, this.sessionSettings, this.poolSettings)
      : _pool = pool.Pool(
          poolSettings?.maxConnectionCount ?? 1000,
        );

  @override
  Future<void> close() async {
    await _pool.close();

    // Connections are closed when they are returned to the pool if it's closed.
    // We still need to close statements that are currently unused.
    for (final connection in _openConnections) {
      if (!connection.isInUse) {
        await connection.connection.close();
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
    L? locality,
  }) {
    return withConnection(
      (connection) => connection.runTx(fn),
      locality: locality,
    );
  }

  @override
  Future<R> withConnection<R>(
    Future<R> Function(Connection connection) fn, {
    SessionSettings? sessionSettings,
    L? locality,
  }) async {
    final resource = await _pool.request();

    _OpenedConnection? connection;
    try {
      final context = EndpointSelectorContext(
        locality: locality,
      );
      final selection = await _selector(context);

      // Find an existing connection that is currently unused, or open another
      // one.
      connection = _openConnections.firstWhereOrNull(
          (c) => !c.isInUse && c.endpoint == selection.endpoint);
      if (connection == null) {
        connection ??= _OpenedConnection(
          selection.endpoint,
          await PgConnectionImplementation.connect(
            selection.endpoint,
            sessionSettings: sessionSettings ?? this.sessionSettings,
          ),
        );
        _openConnections.add(connection);
      }

      connection.isInUse = true;
      final poolConnection = _PoolConnection(connection.connection);
      return await fn(poolConnection);
    } finally {
      resource.release();

      // If the pool has been closed, this connection needs to be closed as
      // well.
      if (_pool.isClosed) {
        await connection?.connection.close();
      } else {
        // Allow the connection to be re-used later.
        connection?.isInUse = false;
      }
    }
  }
}

/// An opened [Connection] we're able to use in [Pool.withConnection].
class _OpenedConnection {
  final Endpoint endpoint;
  final PgConnectionImplementation connection;
  bool isInUse = false;

  _OpenedConnection(this.endpoint, this.connection);
}

class _PoolConnection implements Connection {
  final PgConnectionImplementation _connection;

  _PoolConnection(this._connection);

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
  Future<R> runTx<R>(Future<R> Function(Session session) fn) {
    return _connection.runTx(fn);
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
