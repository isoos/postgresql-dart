part of postgres;

typedef Future<dynamic> _TransactionQuerySignature(PostgreSQLExecutionContext connection);

class _TransactionProxy implements PostgreSQLExecutionContext {
  _TransactionProxy(this.connection, this.executionBlock) {
    beginQuery = new _Query<int>("BEGIN", {}, connection, this)
      ..onlyReturnAffectedRowCount = true;

    beginQuery.onComplete.future
        .then(startTransaction)
        .catchError(handleTransactionQueryError);
  }

  _Query beginQuery;
  Completer completer = new Completer();
  Future get future => completer.future;

  _Query get pendingQuery {
    if (queryQueue.length > 0) {
      return queryQueue.first;
    }

    return null;
  }
  List<_Query> queryQueue = [];
  PostgreSQLConnection connection;
  _TransactionQuerySignature executionBlock;

  Future commit() async {
    await execute("COMMIT");
  }

  Future<List<List<dynamic>>> query(String fmtString, {Map<String, dynamic> substitutionValues: null, bool allowReuse: true}) async {
    if (connection.isClosed) {
      throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
    }

    var query = new _Query<List<List<dynamic>>>(fmtString, substitutionValues, connection, this);

    if (allowReuse) {
      query.statementIdentifier = connection._reuseIdentifierForQuery(query);
    }

    return await enqueue(query);
  }

  Future<int> execute(String fmtString, {Map<String, dynamic> substitutionValues: null}) async {
    if (connection.isClosed) {
      throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
    }

    var query = new _Query<int>(fmtString, substitutionValues, connection, this)
      ..onlyReturnAffectedRowCount = true;

    return enqueue(query);
  }

  void cancelTransaction({String reason: null}) {
    throw new _TransactionRollbackException(reason);
  }

  Future startTransaction(dynamic beginResults) async {
    var result;
    try {
      result = await executionBlock(this);
    } on _TransactionRollbackException catch (rollback) {
      queryQueue = [];
      await execute("ROLLBACK");
      completer.complete(new PostgreSQLRollback(rollback.reason));
      return;
    } catch (e) {
      queryQueue = [];

      await execute("ROLLBACK");
      completer.completeError(e);
      return;
    }

    await execute("COMMIT");

    completer.complete(result);
  }

  Future handleTransactionQueryError(dynamic err) async {

  }

  Future<dynamic> enqueue(_Query query) async {
    queryQueue.add(query);
    connection._transitionToState(connection._connectionState.awake());

    var result = null;
    try {
      result = await query.future;

      connection._cacheQuery(query);
      queryQueue.remove(query);
    } catch (e) {
      connection._cacheQuery(query);
      queryQueue.remove(query);
      rethrow;
    }

    return result;
  }
}

class PostgreSQLRollback {
  PostgreSQLRollback(this.reason);

  String reason;
}