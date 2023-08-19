import 'dart:async';

import 'package:pool/pool.dart';
import 'package:postgres/postgres_v3_experimental.dart';

import 'connection.dart';

class PoolImplementation implements PgPool {
  final List<PgEndpoint> endpoints;
  final PgSessionSettings? sessionSettings;
  final PgPoolSettings? poolSettings;

  final Pool _pool;
  final List<_OpenedConnection> _openConnections = [];

  int _nextEndpointIndex = 0;

  PoolImplementation(this.endpoints, this.sessionSettings, this.poolSettings)
      : _pool = Pool(
          poolSettings?.maxConnectionCount ?? 1000,
        );

  /// Returns the next endpoint from [endpoints], cycling through them.
  PgEndpoint get _nextEndpoint {
    final endpoint = endpoints[_nextEndpointIndex];
    _nextEndpointIndex = (_nextEndpointIndex + 1) % endpoints.length;

    return endpoint;
  }

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
  Future<PgResult> execute(Object query,
      {Object? parameters, bool ignoreRows = false}) {
    return withConnection((connection) => connection.execute(
          query,
          parameters: parameters,
          ignoreRows: ignoreRows,
        ));
  }

  @override
  Future<PgStatement> prepare(Object query) async {
    final statementCompleter = Completer<PgStatement>.sync();

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
  Future<R> run<R>(Future<R> Function(PgSession session) fn) {
    return withConnection((connection) => connection.run(fn));
  }

  @override
  Future<R> runTx<R>(Future<R> Function(PgSession session) fn) {
    return withConnection((connection) => connection.runTx(fn));
  }

  @override
  Future<R> withConnection<R>(Future<R> Function(PgConnection connection) fn,
      {PgSessionSettings? sessionSettings}) async {
    final resource = await _pool.request();

    // Find an existing connection that is currently unused, or open another
    // one.
    _OpenedConnection? connection;
    for (final opened in _openConnections) {
      if (!opened.isInUse) {
        connection = opened;
        break;
      }
    }

    try {
      if (connection == null) {
        connection ??= _OpenedConnection(
          await PgConnectionImplementation.connect(
            _nextEndpoint,
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

/// An opened [PgConnection] we're able to use in [PgPool.withConnection].
class _OpenedConnection {
  bool isInUse = false;
  final PgConnectionImplementation connection;

  _OpenedConnection(this.connection);
}

class _PoolConnection implements PgConnection {
  final PgConnectionImplementation _connection;

  _PoolConnection(this._connection);

  @override
  PgChannels get channels {
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
  Future<PgResult> execute(Object query,
      {Object? parameters, bool ignoreRows = false}) {
    return _connection.execute(
      query,
      parameters: parameters,
      ignoreRows: ignoreRows,
    );
  }

  @override
  Future<PgStatement> prepare(Object query) {
    return _connection.prepare(query);
  }

  @override
  Future<R> run<R>(Future<R> Function(PgSession session) fn) {
    return _connection.run(fn);
  }

  @override
  Future<R> runTx<R>(Future<R> Function(PgSession session) fn) {
    return _connection.runTx(fn);
  }
}

class _PoolStatement implements PgStatement {
  final Completer<void> _disposed = Completer();
  final PgStatement _underlying;

  _PoolStatement(this._underlying);

  @override
  PgResultStream bind(Object? parameters) => _underlying.bind(parameters);

  @override
  Future<void> dispose() async {
    _disposed.complete();
    await _underlying.dispose();
  }

  @override
  Future<PgResult> run([Object? parameters]) {
    return _underlying.run(parameters);
  }
}
