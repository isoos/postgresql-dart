part of postgres.connection;

typedef Future<dynamic> _TransactionQuerySignature(PostgreSQLExecutionContext connection);

class _TransactionProxy extends Object with _PostgreSQLExecutionContextMixin implements PostgreSQLExecutionContext {
  _TransactionProxy(this._connection, this.executionBlock) {
    beginQuery = new Query<int>("BEGIN", {}, _connection, this)..onlyReturnAffectedRowCount = true;

    beginQuery.future.then(startTransaction).catchError((err, st) {
      new Future(() {
        completer.completeError(err, st);
      });
    });
  }

  Query<dynamic> beginQuery;
  Completer completer = new Completer();

  Future get future => completer.future;

  final PostgreSQLConnection _connection;

  PostgreSQLExecutionContext get _transaction => this;

  _TransactionQuerySignature executionBlock;
  bool _hasFailed = false;
  bool _hasRolledBack = false;

  void cancelTransaction({String reason: null}) {
    throw new _TransactionRollbackException(reason);
  }

  Future startTransaction(dynamic _) async {
    var result;
    try {
      result = await executionBlock(this);

      // Place another event in the queue so that any non-awaited futures
      // in the executionBlock are given a chance to run
      await new Future(() => null);
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
      await execute("COMMIT");
      completer.complete(result);
    }
  }

  Future _cancelAndRollback(dynamic object, [StackTrace trace]) async {
    if (_hasRolledBack) {
      return;
    }

    _hasRolledBack = true;
    // We'll wrap each query in an error handler here to make sure the query cancellation error
    // is only emitted from the transaction itself.
    _queue.forEach((q) {
      q.future.catchError((_) {});
    });

    final err = new PostgreSQLException("Query failed prior to execution. "
        "This query's transaction encountered an error earlier in the transaction "
        "that prevented this query from executing.");
    _queue.cancel(err);

    var rollback = new Query<int>("ROLLBACK", {}, _connection, _transaction)..onlyReturnAffectedRowCount = true;
    _queue.addEvenIfCancelled(rollback);

    _connection._transitionToState(_connection._connectionState.awake());

    try {
      await rollback.future.timeout(new Duration(seconds: 30));
    } finally {
      _queue.remove(rollback);
    }

    if (object is _TransactionRollbackException) {
      completer.complete(new PostgreSQLRollback._(object.reason));
    } else {
      completer.completeError(object, trace);
    }
  }

  Future _transactionFailed(dynamic error, [StackTrace trace]) async {
    if (_hasFailed) {
      return;
    }

    _hasFailed = true;

    await _cancelAndRollback(error, trace);
  }

  @override
  Future _onQueryError(Query query, dynamic error, [StackTrace trace]) {
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
  String reason;
}
