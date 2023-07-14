part of postgres.connection;

typedef _TransactionQuerySignature = Future<dynamic> Function(
    PostgreSQLExecutionContext connection);

class _TransactionProxy extends Object
    with _PostgreSQLExecutionContextMixin
    implements PostgreSQLExecutionContext {
  _TransactionProxy(
      this._connection, this.executionBlock, this.commitTimeoutInSeconds) {
    _beginQuery = Query<int>('BEGIN', <String,dynamic>{}, _connection, this, StackTrace.current,
        onlyReturnAffectedRowCount: true,placeholderIdentifier: PlaceholderIdentifier.atSign);

    _beginQuery.future
        .then(startTransaction)
        .catchError((Object err, StackTrace st) {
      Future(() {
        _completer.completeError(err, st);
      });
    });
  }

  late Query<dynamic> _beginQuery;
  final _completer = Completer();

  Future get future => _completer.future;

  @override
  final PostgreSQLConnection _connection;

  @override
  PostgreSQLExecutionContext get _transaction => this;

  final _TransactionQuerySignature executionBlock;
  final int? commitTimeoutInSeconds;
  bool _hasFailed = false;
  bool _hasRolledBack = false;

  @override
  void cancelTransaction({String? reason}) {
    throw _TransactionRollbackException(reason ?? 'Reason not given.');
  }

  Future startTransaction(dynamic _) async {
    dynamic result;
    try {
      result = await executionBlock(this);

      // Place another event in the queue so that any non-awaited futures
      // in the executionBlock are given a chance to run
      await Future(() => null);
    } on _TransactionRollbackException catch (rollback) {
      await _cancelAndRollback(rollback);

      return;
    } catch (e, st) {
      await _transactionFailed(e, st);

      return;
    }

    // If we have queries pending, we need to wait for them to complete
    // before finishing !!!!
    if (_queue.isNotEmpty) {
      // ignore the error from this query if there is one, it'll pop up elsewhere
      await _queue.last.future.catchError((_) {});
    }

    if (!_hasRolledBack && !_hasFailed) {
      await execute('COMMIT', timeoutInSeconds: commitTimeoutInSeconds);
      _completer.complete(result);
    }
  }

  Future _cancelAndRollback(dynamic object, [StackTrace? trace]) async {
    if (_hasRolledBack) {
      return;
    }

    _hasRolledBack = true;
    // We'll wrap each query in an error handler here to make sure the query cancellation error
    // is only emitted from the transaction itself.
    for (final q in _queue) {
      unawaited(q.future.catchError((_) {}));
    }

    final err = PostgreSQLException('Query failed prior to execution. '
        "This query's transaction encountered an error earlier in the transaction "
        'that prevented this query from executing.');
    _queue.cancel(err);

    final rollback = Query<int>(
        'ROLLBACK', <String, dynamic>{}, _connection, _transaction, StackTrace.current,
        onlyReturnAffectedRowCount: true,placeholderIdentifier: PlaceholderIdentifier.atSign);
    _queue.addEvenIfCancelled(rollback);

    _connection._transitionToState(_connection._connectionState.awake());

    try {
      await rollback.future.timeout(Duration(seconds: 30));
    } finally {
      _queue.remove(rollback);
    }

    if (object is _TransactionRollbackException) {
      _completer.complete(PostgreSQLRollback._(object.reason));
    } else {
      _completer.completeError(object as Object, trace);
    }
  }

  Future _transactionFailed(dynamic error, [StackTrace? trace]) async {
    if (_hasFailed) {
      return;
    }

    _hasFailed = true;

    await _cancelAndRollback(error, trace);
  }

  @override
  Future _onQueryError(Query query, dynamic error, [StackTrace? trace]) {
    return _transactionFailed(error, trace);
  }
}

/// Represents a rollback from a transaction.
///
/// If a transaction is cancelled using [PostgreSQLExecutionContext.cancelTransaction], the value of the [Future]
/// returned from [PostgreSQLConnection.transaction] will be an instance of this type. [reason] will be the [String]
/// value of the optional argument to [PostgreSQLExecutionContext.cancelTransaction].
class PostgreSQLRollback {
  PostgreSQLRollback._(this.reason);

  /// The reason the transaction was cancelled.
  final String reason;

  @override
  String toString() => 'PostgreSQLRollback: $reason';
}
