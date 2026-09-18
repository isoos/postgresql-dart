import 'dart:async';

import 'package:collection/collection.dart';
import 'package:pool/pool.dart' as pool;
import 'package:postgres/src/utils/package_pool_ext.dart';

import '../../postgres.dart';
import '../v3/connection.dart';
import '../v3/resolved_settings.dart';

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
  final ResolvedPoolSettings _settings;

  final _connections = <_PoolConnection>[];
  late final _maxConnectionCount = _settings.maxConnectionCount;
  late final _semaphore = pool.Pool(_maxConnectionCount);
  late final _connectLock = pool.Pool(1);
  bool _closing = false;

  PoolImplementation(this._selector, PoolSettings? settings)
    : _settings = ResolvedPoolSettings(settings);

  @override
  bool get isOpen => !_closing;

  @override
  Future<void> get closed => _semaphore.done;

  @override
  Future<void> close({bool force = false}) async {
    _closing = true;
    final semaphoreFuture = _semaphore.close();

    // A `withConnection` call that already acquired a semaphore permit
    // before `_closing` was set may still be inside `_selectOrCreate`,
    // creating a brand new connection that hasn't been added to
    // `_connections` yet - invisible to the snapshot below unless we wait
    // for it here. `_connectLock` serializes connection creation, so
    // acquiring and releasing it once guarantees any such in-flight creation
    // has either finished (and added itself to `_connections`) or bailed out
    // (since `_selectOrCreate` itself checks `_closing`) before we proceed.
    await _connectLock.withResource(() {});

    // Connections are closed when they are returned to the pool if it's closed.
    // We still need to close statements that are currently unused.
    final snapshot = [..._connections];
    for (final connection in snapshot) {
      if (force || !connection._isInUse) {
        await connection._dispose(force: force);
      }
    }

    // Connections that were in use at the time of this call are skipped
    // above and torn down later by their own `withConnection` call, once it
    // notices `_closing`. Wait for that to actually happen, so this method
    // doesn't return while a connection is still mid-teardown.
    await Future.wait(snapshot.map((c) => c.closed));

    await semaphoreFuture;
  }

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) {
    return withConnection(
      (connection) => connection.execute(
        query,
        parameters: parameters,
        ignoreRows: ignoreRows,
        queryMode: queryMode,
        timeout: timeout,
      ),
    );
  }

  @override
  Future<Statement> prepare(Object query) async {
    final statementCompleter = Completer<Statement>();

    unawaited(() async {
      try {
        await withConnection((connection) async {
          _PoolStatement? poolStatement;

          try {
            final statement = await connection.prepare(query);
            poolStatement = _PoolStatement(statement);
          } on Object catch (e, s) {
            // Could not prepare the statement, inform the caller and stop
            // occupying the connection. Rethrow (after completing the
            // completer below) so `withConnection`'s own error handling
            // marks the connection as not to be reused - matching every
            // other pool operation (`execute`/`run`/`runTx`), which already
            // discard the connection on any exception from `fn`.
            statementCompleter.completeError(e, s);
            rethrow;
          }

          // Otherwise, make the future returned by prepare complete with the
          // statement.
          statementCompleter.complete(poolStatement);

          // And keep this connection reserved until the statement has been disposed.
          return poolStatement._disposed.future;
        });
      } on Object catch (e, s) {
        // withConnection itself may fail before `fn` ever runs (e.g. no
        // connection could be acquired in time) - make sure that surfaces to
        // the caller instead of leaving `statementCompleter` pending forever.
        if (!statementCompleter.isCompleted) {
          statementCompleter.completeError(e, s);
        }
      }
    }());

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
    Future<R> Function(TxSession session) fn, {
    TransactionSettings? settings,
    L? locality,
  }) {
    return withConnection(
      (connection) => connection.runTx(fn, settings: settings),
      locality: locality,
    );
  }

  @override
  Future<R> withConnection<R>(
    Future<R> Function(Connection connection) fn, {
    ConnectionSettings? settings,
    L? locality,
  }) async {
    final connectSw = Stopwatch()..start();
    final resource = await _semaphore.requestWithTimeout(
      _settings.connectTimeout,
    );
    _PoolConnection? connection;
    bool reuse = true;
    final sw = Stopwatch();
    try {
      final context = EndpointSelectorContext(locality: locality);
      final selection = await _selector(context);

      // Find an existing connection that is currently unused, or open another
      // one. Only the time left over from the semaphore wait above is
      // available here - otherwise this call could wait up to roughly twice
      // the configured `connectTimeout` before failing.
      final remainingTimeout = _settings.connectTimeout - connectSw.elapsed;
      connection = await _selectOrCreate(
        selection.endpoint,
        ResolvedConnectionSettings(settings, _settings),
        remainingTimeout,
      );

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

      // If the pool has been closed, this connection needs to be closed as
      // well.
      if (connection != null) {
        connection._elapsedInUse += sw.elapsed;
        if (_closing || !reuse || !connection.isOpen) {
          await connection._dispose();
        } else {
          // Allow the connection to be re-used later.
          connection._isInUse = false;
          connection._lastReturned = DateTime.now();
        }
      }
    }
  }

  Future<_PoolConnection> _selectOrCreate(
    Endpoint endpoint,
    ResolvedConnectionSettings settings,
    Duration timeout,
  ) async {
    final oldc = _connections.firstWhereOrNull(
      (c) => c._mayReuse(endpoint, settings),
    );
    if (oldc != null) {
      // NOTE: It is important to update the _isInUse flag here, otherwise
      //       race conditions may create conflicts.
      oldc._isInUse = true;
      return oldc;
    }

    return await _connectLock.withRequestTimeout(
      timeout: timeout,
      (remainingTimeout) async {
        if (_closing) {
          throw PgException('The pool is closing, cannot open a connection.');
        }
        while (_connections.length >= _maxConnectionCount) {
          final candidates = _connections
              .where((c) => c._isInUse == false)
              .toList();
          if (candidates.isEmpty) {
            throw StateError('The pool should not be in this state.');
          }
          final selected = candidates.reduce(
            (a, b) => a._lastReturned.isBefore(b._lastReturned) ? a : b,
          );
          await selected._dispose();
        }

        final connectFuture = PgConnectionImplementation.connect(
          endpoint,
          connectionSettings: settings,
        );
        final PgConnectionImplementation connection;
        try {
          connection = await connectFuture.timeout(remainingTimeout);
        } on TimeoutException {
          // `.timeout()` doesn't cancel `connectFuture` - if it later
          // succeeds anyway, close the resulting connection instead of
          // leaking its socket (it was never added to `_connections`, so
          // nothing else would ever close it).
          unawaited(
            connectFuture
                .then((c) => c.close(force: true))
                .catchError((_) {}),
          );
          rethrow;
        }

        final newc = _PoolConnection(this, endpoint, settings, connection);
        newc._isInUse = true;
        // NOTE: It is important to update _connections list after the isInUse
        //       flag is set, otherwise race conditions may create conflicts or
        //       pool close may miss the connection.
        _connections.add(newc);
        return newc;
      },
    );
  }
}

/// An opened [Connection] we're able to use in [Pool.withConnection].
class _PoolConnection implements Connection {
  final _opened = DateTime.now();
  final PoolImplementation _pool;
  final Endpoint _endpoint;
  final ResolvedConnectionSettings _connectionSettings;
  final PgConnectionImplementation _connection;
  Duration _elapsedInUse = Duration.zero;
  DateTime _lastReturned = DateTime.now();
  bool _isInUse = false;

  _PoolConnection(
    this._pool,
    this._endpoint,
    this._connectionSettings,
    this._connection,
  );

  bool _mayReuse(Endpoint endpoint, ResolvedConnectionSettings settings) {
    if (_isInUse || endpoint != _endpoint || _isExpired() || !isOpen) {
      return false;
    }
    if (!_connectionSettings.isMatchingConnection(settings)) {
      return false;
    }
    return true;
  }

  bool _isExpired() {
    final age = DateTime.now().difference(_opened);
    if (age >= _pool._settings.maxConnectionAge) {
      return true;
    }
    if (_elapsedInUse >= _pool._settings.maxSessionUse) {
      return true;
    }
    if (_connection.queryCount >= _pool._settings.maxQueryCount) {
      return true;
    }
    return false;
  }

  Future<void> _dispose({bool force = false}) async {
    _pool._connections.remove(this);
    await _connection.close(force: force);
  }

  @override
  bool get isOpen => _connection.isOpen;

  @override
  Future<void> get closed => _connection.closed;

  @override
  ConnectionInfo get info => _connection.info;

  @override
  Channels get channels {
    throw UnsupportedError(
      'Channels are not supported in pools because they would require keeping '
      'the connection open even after `withConnection` has returned.',
    );
  }

  @override
  Future<void> close({bool force = false}) async {
    // Don't forward the close call unless forcing. The underlying connection should be re-used
    // when another pool connection is requested.

    if (force) {
      await _connection.close(force: force);
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
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    SessionSettings? settings,
  }) {
    return _connection.run(fn, settings: settings);
  }

  @override
  Future<R> runTx<R>(
    Future<R> Function(TxSession session) fn, {
    TransactionSettings? settings,
  }) {
    return _connection.runTx(fn, settings: settings);
  }
}

class _PoolStatement implements Statement {
  final _disposed = Completer<void>();
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
  Future<Result> run(Object? parameters, {Duration? timeout}) {
    return _underlying.run(parameters, timeout: timeout);
  }
}
