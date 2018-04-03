part of postgres.connection;

typedef Future<dynamic> _TransactionQuerySignature(PostgreSQLExecutionContext connection);

class _TransactionProxy extends Object with _PostgreSQLExecutionContextMixin implements PostgreSQLExecutionContext {
  _TransactionProxy(this._connection, this.executionBlock) {
    beginQuery = new Query<int>("BEGIN", {}, _connection, this)..onlyReturnAffectedRowCount = true;

    beginQuery.future.then(startTransaction).catchError(_onBeginFailure);
  }

  Query<dynamic> beginQuery;
  Completer completer = new Completer();

  Future get future => completer.future;

  final PostgreSQLConnection _connection;
  PostgreSQLExecutionContext get _transaction => this;

  _TransactionQuerySignature executionBlock;
  bool _hasFailed = false;

  Future commit() async {
    await execute("COMMIT");
  }

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
      _queue.clear();
      await execute("ROLLBACK");
      completer.complete(new PostgreSQLRollback._(rollback.reason));
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

    await execute("COMMIT");

    completer.complete(result);
  }

  Future _onBeginFailure(dynamic err) async {
    completer.completeError(err);
  }

  Future _transactionFailed(dynamic error, [StackTrace trace]) async {
    if (!_hasFailed) {
      _hasFailed = true;
      _queue.clear();
      await execute("ROLLBACK");
      completer.completeError(error, trace);
    }
  }

  @override
  Future _onQueryError(Query query, dynamic error, [StackTrace trace]) async {
    await _transactionFailed(error, trace);
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
