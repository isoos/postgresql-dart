part of postgres;

typedef Future<dynamic> _TransactionQuerySignature(PostgreSQLExecutionContext connection);

class _TransactionProxy implements PostgreSQLExecutionContext {
  _TransactionProxy(this.connection, this.executionBlock) {
    beginQuery = new _Query<int>("BEGIN", {}, connection, this)
      ..onlyReturnAffectedRowCount = true;

    queryQueue.add(beginQuery);
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

  /*
    try {
      var results = await queryBlock(proxy);
      await proxy.commit();

      return results;
    } on _TransactionRollbackException {
      return null;
    } finally {
      _transactionQueue.remove(proxy);
    }
   */

  Future commit() async {
    await execute("COMMIT");
  }

  Future<List<List<dynamic>>> query(String fmtString, {Map<String, dynamic> substitutionValues: null, bool allowReuse: true}) async {
    if (connection.isClosed) {
      throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
    }

    var query = new _Query<List<List<dynamic>>>(fmtString, substitutionValues, connection, this)
      ..allowReuse = allowReuse;

    queryQueue.add(query);
    connection._transitionToState(connection._connectionState.awake());

    return query.future;
  }

  Future<int> execute(String fmtString, {Map<String, dynamic> substitutionValues: null}) async {
    if (connection.isClosed) {
      throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
    }

    var query = new _Query<int>(fmtString, substitutionValues, connection, this)
      ..onlyReturnAffectedRowCount = true;

    queryQueue.add(query);

    connection._transitionToState(connection._connectionState.awake());

    return query.future;
  }

  Future cancelTransaction({String reason: null}) async {
    await execute("ROLLBACK");
    throw new _TransactionRollbackException(reason);
  }

  void cancelWithError(dynamic error) {

  }

  void finalizeQuery(_Query q) {
    queryQueue.remove(q);

    if (identical(q, beginQuery)) {
      executionBlock(this)
        .then(commitAndComplete)
        .catchError((err, st) {
          if (err is _TransactionRollbackException) {
            connection._finalizeTransaction(this);
            completer.complete(new PostgreSQLRollback(err.reason));
          } else {
            connection._finalizeTransaction(this);
            completer.completeError(err, st);
          }
        });
    }
  }

  Future commitAndComplete(dynamic returnValue) async {
    await execute("COMMIT");
    connection._finalizeTransaction(this);
    completer.complete(returnValue);
  }
}

class PostgreSQLRollback {
  PostgreSQLRollback(this.reason);

  String reason;
}