part of postgres.connection;

abstract class _PostgreSQLConnectionState {
  PostgreSQLConnection? connection;

  _PostgreSQLConnectionState onEnter() {
    return this;
  }

  _PostgreSQLConnectionState awake() {
    return this;
  }

  _PostgreSQLConnectionState onMessage(ServerMessage message) {
    return this;
  }

  _PostgreSQLConnectionState onErrorResponse(ErrorResponseMessage message) {
    final exception = PostgreSQLException._(message.fields);

    if (exception.severity == PostgreSQLSeverity.fatal ||
        exception.severity == PostgreSQLSeverity.panic) {
      return _PostgreSQLConnectionStateClosed();
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

  @override
  _PostgreSQLConnectionState onEnter() {
    final startupMessage = StartupMessage(
        connection!.databaseName, connection!.timeZone,
        username: connection!.username,
        replication: connection!.replicationMode);

    connection!._socket!.add(startupMessage.asBytes());

    return _PostgreSQLConnectionStateAuthenticating(completer);
  }

  @override
  _PostgreSQLConnectionState onErrorResponse(ErrorResponseMessage message) {
    final exception = PostgreSQLException._(message.fields);

    completer.completeError(exception);

    return _PostgreSQLConnectionStateClosed();
  }

  @override
  _PostgreSQLConnectionState onMessage(ServerMessage message) {
    completer.completeError(PostgreSQLException(
        'Unsupported message "$message", closing connection.'));

    return _PostgreSQLConnectionStateClosed();
  }
}

/*
  Authenticating state
 */

class _PostgreSQLConnectionStateAuthenticating
    extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionStateAuthenticating(this.completer);

  Completer completer;
  late PostgresAuthenticator _authenticator;

  @override
  _PostgreSQLConnectionState onEnter() {
    return this;
  }

  @override
  _PostgreSQLConnectionState onErrorResponse(ErrorResponseMessage message) {
    final exception = PostgreSQLException._(message.fields);

    completer.completeError(exception);

    return _PostgreSQLConnectionStateClosed();
  }

  @override
  _PostgreSQLConnectionState onMessage(ServerMessage message) {
    if (message is AuthenticationMessage) {
      // Pass on the pending op to subsequent stages
      switch (message.type) {
        case AuthenticationMessage.KindOK:
          return _PostgreSQLConnectionStateAuthenticated(completer);
        case AuthenticationMessage.KindMD5Password:
          // this means the server is requesting an md5 challenge
          // so the password must not be null
          if (connection!.password == null) {
            completer.completeError(PostgreSQLException(
              'Password is required for "${connection!.username}" user to establish a connection',
            ));
            break;
          }
          _authenticator =
              createAuthenticator(connection!, AuthenticationScheme.MD5);
          continue authMsg;
        case AuthenticationMessage.KindClearTextPassword:
          if (connection!.allowClearTextPassword) {
            _authenticator =
                createAuthenticator(connection!, AuthenticationScheme.CLEAR);
            continue authMsg;
          } else {
            completer.completeError(PostgreSQLException(
                'type ${message.type} connections disabled. Set AllowClearTextPassword flag on PostgreSQLConnection to enable this feature.'));
            break;
          }
        case AuthenticationMessage.KindSASL:
          // this means the server is requesting a scram-sha-256 challenge
          // so the password must not be null
          if (connection!.password == null) {
            completer.completeError(PostgreSQLException(
              'Password is required for "${connection!.username}" user to establish a connection',
            ));
            break;
          }
          _authenticator = createAuthenticator(
              connection!, AuthenticationScheme.SCRAM_SHA_256);
          continue authMsg;
        authMsg:
        case AuthenticationMessage.KindSASLContinue:
        case AuthenticationMessage.KindSASLFinal:
          try {
            _authenticator.onMessage(message);
            return this;
          } catch (e, st) {
            // an exception occurred in the authenticator that isn't a PostgreSQL
            // Exception (e.g. `Null check operator used on a null value`)
            completer.completeError(e, st);
            break;
          }
      }

      completer.completeError(PostgreSQLException(
          'Unsupported authentication type ${message.type}, closing connection.'));
    } else if (message is ParameterStatusMessage) {
      connection!.settings[message.name] = message.value;
    } else if (message is BackendKeyMessage) {
      connection!._processID = message.processID;
      connection!._secretKey = message.secretKey;
    } else if (message is ReadyForQueryMessage) {
      if (message.state == ReadyForQueryMessage.StateIdle) {
        return _PostgreSQLConnectionStateIdle(openCompleter: completer);
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

  @override
  _PostgreSQLConnectionState onErrorResponse(ErrorResponseMessage message) {
    final exception = PostgreSQLException._(message.fields);

    completer.completeError(exception);

    return _PostgreSQLConnectionStateClosed();
  }

  @override
  _PostgreSQLConnectionState onMessage(ServerMessage message) {
    if (message is ParameterStatusMessage) {
      connection!.settings[message.name] = message.value;
    } else if (message is BackendKeyMessage) {
      connection!._processID = message.processID;
      connection!._secretKey = message.secretKey;
    } else if (message is ReadyForQueryMessage) {
      if (message.state == ReadyForQueryMessage.StateIdle) {
        return _PostgreSQLConnectionStateIdle(openCompleter: completer);
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

  Completer? openCompleter;

  @override
  _PostgreSQLConnectionState awake() {
    final pendingQuery = connection!._queue.pending;
    if (pendingQuery != null) {
      return processQuery(pendingQuery);
    }

    return this;
  }

  _PostgreSQLConnectionState processQuery(Query<dynamic> q) {
    try {
      if (q.onlyReturnAffectedRowCount || q.useSendSimple) {
        q.sendSimple(connection!._socket!);
        return _PostgreSQLConnectionStateBusy(q);
      }

      final cached = connection!._cache[q.statement];
      q.sendExtended(connection!._socket!, cacheQuery: cached);

      return _PostgreSQLConnectionStateBusy(q);
    } catch (e, st) {
      scheduleMicrotask(() {
        q.completeError(e, st);
        connection!._transitionToState(_PostgreSQLConnectionStateIdle());
      });

      return _PostgreSQLConnectionStateDeferredFailure();
    }
  }

  @override
  _PostgreSQLConnectionState onEnter() {
    openCompleter?.complete();

    return awake();
  }

  @override
  _PostgreSQLConnectionState onMessage(ServerMessage message) {
    return this;
  }
}

/*
  Busy state, query in progress
 */

class _PostgreSQLConnectionStateBusy extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionStateBusy(this.query);

  Query<dynamic> query;
  PostgreSQLException? returningException;
  int rowsAffected = 0;

  @override
  _PostgreSQLConnectionState onErrorResponse(ErrorResponseMessage message) {
    // If we get an error here, then we should eat the rest of the messages
    // and we are always confirmed to get a _ReadyForQueryMessage to finish up.
    // We should only report the error once that is done.
    final exception = PostgreSQLException._(message.fields);
    returningException ??= exception;

    if (exception.severity == PostgreSQLSeverity.fatal ||
        exception.severity == PostgreSQLSeverity.panic) {
      return _PostgreSQLConnectionStateClosed();
    }

    return this;
  }

  @override
  _PostgreSQLConnectionState onMessage(ServerMessage message) {
    // We ignore NoData, as it doesn't tell us anything we don't already know
    // or care about.

    // print("(${query.statement}) -> $message");

    if (message is ReadyForQueryMessage) {
      if (message.state == ReadyForQueryMessage.StateTransactionError) {
        query.completeError(returningException!);
        return _PostgreSQLConnectionStateReadyInTransaction(
            query.transaction as _PostgreSQLExecutionContextMixin);
      }
      if (returningException != null) {
        query.completeError(returningException!);
      } else {
        query.complete(rowsAffected);
      }

      if (message.state == ReadyForQueryMessage.StateTransaction) {
        return _PostgreSQLConnectionStateReadyInTransaction(
            query.transaction as _PostgreSQLExecutionContextMixin);
      }

      return _PostgreSQLConnectionStateIdle();
    } else if (message is CommandCompleteMessage) {
      rowsAffected = message.rowsAffected;
    } else if (message is RowDescriptionMessage) {
      query.fieldDescriptions = message.fieldDescriptions;
    } else if (message is DataRowMessage) {
      query.addRow(message.values);
    } else if (message is ParameterDescriptionMessage) {
      final validationException =
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

  _PostgreSQLExecutionContextMixin transaction;

  @override
  _PostgreSQLConnectionState onEnter() {
    return awake();
  }

  @override
  _PostgreSQLConnectionState awake() {
    final pendingQuery = transaction._queue.pending;
    if (pendingQuery != null) {
      return processQuery(pendingQuery);
    }

    return this;
  }

  _PostgreSQLConnectionState processQuery(Query<dynamic> q) {
    try {
      if (q.onlyReturnAffectedRowCount || q.useSendSimple) {
        q.sendSimple(connection!._socket!);
        return _PostgreSQLConnectionStateBusy(q);
      }

      final cached = connection!._cache[q.statement];
      q.sendExtended(connection!._socket!, cacheQuery: cached);

      return _PostgreSQLConnectionStateBusy(q);
    } catch (e, st) {
      scheduleMicrotask(() {
        q.completeError(e, st);
      });

      return this;
    }
  }
}

/*
  Hack for deferred error
 */

class _PostgreSQLConnectionStateDeferredFailure
    extends _PostgreSQLConnectionState {}
