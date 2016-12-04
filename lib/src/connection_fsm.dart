part of postgres;

abstract class _PostgreSQLConnectionState {
  PostgreSQLConnection connection;

  _PostgreSQLConnectionState onEnter() {
    return this;
  }

  _PostgreSQLConnectionState awake() {
    return this;
  }

  _PostgreSQLConnectionState onMessage(_ServerMessage message) {
    return this;
  }

  _PostgreSQLConnectionState onErrorResponse(_ErrorResponseMessage message) {
    var exception = new PostgreSQLException._(message.fields);

    if (exception.severity == PostgreSQLSeverity.fatal ||
        exception.severity == PostgreSQLSeverity.panic) {
      return new _PostgreSQLConnectionStateClosed();
    }

    return this;
  }

  void onExit() {}
}

/*
  Closed State; starts here and ends here.
 */

class _PostgreSQLConnectionStateClosed extends _PostgreSQLConnectionState {}

/*
  Socket connected, prior to any PostgreSQL handshaking - initiates that handshaking
 */

class _PostgreSQLConnectionStateSocketConnected
    extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionStateSocketConnected(this.completer);

  Completer completer;

  _PostgreSQLConnectionState onEnter() {
    var startupMessage = new _StartupMessage(
        connection.databaseName, connection.timeZone,
        username: connection.username);

    connection._socket.add(startupMessage.asBytes());

    return this;
  }

  _PostgreSQLConnectionState onErrorResponse(_ErrorResponseMessage message) {
    var exception = new PostgreSQLException._(message.fields);

    completer.completeError(exception);

    return new _PostgreSQLConnectionStateClosed();
  }

  _PostgreSQLConnectionState onMessage(_ServerMessage message) {
    _AuthenticationMessage authMessage = message;

    // Pass on the pending op to subsequent stages
    if (authMessage.type == _AuthenticationMessage.KindOK) {
      return new _PostgreSQLConnectionStateAuthenticated(completer);
    } else if (authMessage.type == _AuthenticationMessage.KindMD5Password) {
      connection._salt = authMessage.salt;

      return new _PostgreSQLConnectionStateAuthenticating(completer);
    }

    completer.completeError(
        new PostgreSQLException("Unsupported authentication type ${authMessage
            .type}, closing connection."));

    return new _PostgreSQLConnectionStateClosed();
  }
}

/*
  Authenticating state
 */

class _PostgreSQLConnectionStateAuthenticating
    extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionStateAuthenticating(this.completer);

  Completer completer;

  _PostgreSQLConnectionState onEnter() {
    var authMessage = new _AuthMD5Message(
        connection.username, connection.password, connection._salt);

    connection._socket.add(authMessage.asBytes());

    return this;
  }

  _PostgreSQLConnectionState onErrorResponse(_ErrorResponseMessage message) {
    var exception = new PostgreSQLException._(message.fields);

    completer.completeError(exception);

    return new _PostgreSQLConnectionStateClosed();
  }

  _PostgreSQLConnectionState onMessage(_ServerMessage message) {
    if (message is _ParameterStatusMessage) {
      connection.settings[message.name] = message.value;
    } else if (message is _BackendKeyMessage) {
      connection._secretKey = message.secretKey;
      connection._processID = message.processID;
    } else if (message is _ReadyForQueryMessage) {
      if (message.state == _ReadyForQueryMessage.StateIdle) {
        return new _PostgreSQLConnectionStateIdle(openCompleter: completer);
      }
    }

    return this;
  }
}

/*
  Authenticated state
 */

class _PostgreSQLConnectionStateAuthenticated
    extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionStateAuthenticated(this.completer);

  Completer completer;

  _PostgreSQLConnectionState onErrorResponse(_ErrorResponseMessage message) {
    var exception = new PostgreSQLException._(message.fields);

    completer.completeError(exception);

    return new _PostgreSQLConnectionStateClosed();
  }

  _PostgreSQLConnectionState onMessage(_ServerMessage message) {
    if (message is _ParameterStatusMessage) {
      connection.settings[message.name] = message.value;
    } else if (message is _BackendKeyMessage) {
      connection._secretKey = message.secretKey;
      connection._processID = message.processID;
    } else if (message is _ReadyForQueryMessage) {
      if (message.state == _ReadyForQueryMessage.StateIdle) {
        return new _PostgreSQLConnectionStateIdle(openCompleter: completer);
      }
    }

    return this;
  }
}

/*
  Ready/idle state
 */

class _PostgreSQLConnectionStateIdle extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionStateIdle({this.openCompleter});

  Completer openCompleter;

  _PostgreSQLConnectionState awake() {
    var pendingQuery = connection._pendingQuery;
    if (pendingQuery != null) {
      return processQuery(pendingQuery);
    }

    return this;
  }

  _PostgreSQLConnectionState processQuery(_Query q) {
    try {
      if (q.onlyReturnAffectedRowCount) {
        q.sendSimple(connection._socket);
        return new _PostgreSQLConnectionStateBusy(q);
      }

      var cached = connection._cachedQuery(q.statement);
      q.sendExtended(connection._socket, cacheQuery: cached);

      return new _PostgreSQLConnectionStateBusy(q);
    } catch (e) {
      scheduleMicrotask(() {
        q.completeError(e);
        connection._transitionToState(new _PostgreSQLConnectionStateIdle());
      });

      return new _PostgreSQLConnectionStateDeferredFailure();
    }
  }

  _PostgreSQLConnectionState onEnter() {
    openCompleter?.complete();

    return awake();
  }

  _PostgreSQLConnectionState onMessage(_ServerMessage message) {
    return this;
  }
}

/*
  Busy state, query in progress
 */

class _PostgreSQLConnectionStateBusy extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionStateBusy(this.query);

  _Query query;
  PostgreSQLException returningException = null;
  int rowsAffected = 0;

  _PostgreSQLConnectionState onErrorResponse(_ErrorResponseMessage message) {
    // If we get an error here, then we should eat the rest of the messages
    // and we are always confirmed to get a _ReadyForQueryMessage to finish up.
    // We should only report the error once that is done.
    var exception = new PostgreSQLException._(message.fields);
    returningException ??= exception;

    if (exception.severity == PostgreSQLSeverity.fatal ||
        exception.severity == PostgreSQLSeverity.panic) {
      return new _PostgreSQLConnectionStateClosed();
    }

    return this;
  }

  _PostgreSQLConnectionState onMessage(_ServerMessage message) {
    // We ignore NoData, as it doesn't tell us anything we don't already know
    // or care about.

    //print("(${query.statement}) -> $message");

    if (message is _ReadyForQueryMessage) {
      if (message.state == _ReadyForQueryMessage.StateIdle) {
        if (returningException != null) {
          query.completeError(returningException);
        } else {
          query.complete(rowsAffected);
        }

        return new _PostgreSQLConnectionStateIdle();
      } else if (message.state == _ReadyForQueryMessage.StateTransaction) {
        if (returningException != null) {
          query.completeError(returningException);
        } else {
          query.complete(rowsAffected);
        }

        return new _PostgreSQLConnectionStateReadyInTransaction(
            query.transaction);
      } else if (message.state == _ReadyForQueryMessage.StateTransactionError) {
        // This should cancel the transaction, we may have to send a commit here
        query.completeError(returningException);
        return new _PostgreSQLConnectionStateTransactionFailure(
            query.transaction);
      }
    } else if (message is _CommandCompleteMessage) {
      rowsAffected = message.rowsAffected;
    } else if (message is _RowDescriptionMessage) {
      query.fieldDescriptions = message.fieldDescriptions;
    } else if (message is _DataRowMessage) {
      query.addRow(message.values);
    } else if (message is _ParameterDescriptionMessage) {
      var validationException =
          query.validateParameters(message.parameterTypeIDs);
      if (validationException != null) {
        query.cache = null;
      }
      returningException ??= validationException;
    }

    return this;
  }
}

/* Idle Transaction State */

class _PostgreSQLConnectionStateReadyInTransaction
    extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionStateReadyInTransaction(this.transaction);

  _TransactionProxy transaction;

  _PostgreSQLConnectionState onEnter() {
    return awake();
  }

  _PostgreSQLConnectionState awake() {
    var pendingQuery = transaction.pendingQuery;
    if (pendingQuery != null) {
      return processQuery(pendingQuery);
    }

    return this;
  }

  _PostgreSQLConnectionState processQuery(_Query q) {
    try {
      if (q.onlyReturnAffectedRowCount) {
        q.sendSimple(connection._socket);
        return new _PostgreSQLConnectionStateBusy(q);
      }

      var cached = connection._cachedQuery(q.statement);
      q.sendExtended(connection._socket, cacheQuery: cached);

      return new _PostgreSQLConnectionStateBusy(q);
    } catch (e) {
      scheduleMicrotask(() {
        q.completeError(e);
        connection._transitionToState(new _PostgreSQLConnectionStateIdle());
      });

      return new _PostgreSQLConnectionStateDeferredFailure();
    }
  }
}

/*
  Transaction error state
 */

class _PostgreSQLConnectionStateTransactionFailure
    extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionStateTransactionFailure(this.transaction);

  _TransactionProxy transaction;

  _PostgreSQLConnectionState awake() {
    return new _PostgreSQLConnectionStateReadyInTransaction(transaction);
  }
}

/*
  Hack for deferred error
 */

class _PostgreSQLConnectionStateDeferredFailure
    extends _PostgreSQLConnectionState {}
