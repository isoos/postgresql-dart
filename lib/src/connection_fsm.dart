part of postgres;

abstract class _PostgreSQLConnectionState {
  PostgreSQLConnection connection;
  Completer pendingOperation;

  _PostgreSQLConnectionState queueQuery(_Query query) {
    connection._queryQueue.add(query);

    return this;
  }

  _PostgreSQLConnectionState onErrorResponse(_ErrorResponseMessage message) {
    var exception = new PostgreSQLException._(message.fields);
    completeWaitingEvent(null, error: exception);

    if (exception.severity == PostgreSQLSeverity.fatal || exception.severity == PostgreSQLSeverity.panic) {
      return new _PostgreSQLConnectionStateClosed();
    }

    return this;
  }

  _PostgreSQLConnectionState onEnter() {
    return this;
  }

  _PostgreSQLConnectionState onMessage(_ServerMessage message) {
    return this;
  }

  void onExit() {

  }

  void completeWaitingEvent(dynamic data, {dynamic error, StackTrace trace}) {
    var p = pendingOperation;
    pendingOperation = null;

    if (p?.isCompleted ?? true) {
      return;
    }

    scheduleMicrotask(() {
      if (error != null) {
        p?.completeError(error, trace);
      } else {
        p?.complete(data);
      }
    });
  }
}

/*
  Closed State; starts here and ends here.
 */

class _PostgreSQLConnectionStateClosed extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionState queueQuery(_Query query) {
    throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
  }

  _PostgreSQLConnectionState onMessage(_ServerMessage message) {
    return this;
  }
}

/*
  Socket connected, prior to any PostgreSQL handshaking - initiates that handshaking
 */

class _PostgreSQLConnectionStateSocketConnected extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionState queueQuery(_Query query) {
    throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
  }

  _PostgreSQLConnectionState onEnter() {
    var startupMessage = new _StartupMessage(connection.databaseName, connection.timeZone, username: connection.username);

    connection._socket.add(startupMessage.asBytes());
    pendingOperation = new Completer();

    return this;
  }

  _PostgreSQLConnectionState onMessage(_ServerMessage message) {
    _AuthenticationMessage authMessage = message;

    // Pass on the pending op to subsequent stages
    if (authMessage.type == _AuthenticationMessage.KindOK) {
      return new _PostgreSQLConnectionStateAuthenticated()
          ..pendingOperation = pendingOperation;
    } else if (authMessage.type == _AuthenticationMessage.KindMD5Password) {
      connection._salt = authMessage.salt;

      return new _PostgreSQLConnectionStateAuthenticating()
          ..pendingOperation = pendingOperation;
    }

    completeWaitingEvent(null, error: new PostgreSQLException("Unsupported authentication type ${authMessage.type}, closing connection."));

    return new _PostgreSQLConnectionStateClosed();
  }
}

/*
  Authenticating state
 */

class _PostgreSQLConnectionStateAuthenticating extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionState queueQuery(_Query query) {
    throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
  }

  _PostgreSQLConnectionState onEnter() {
    var authMessage = new _AuthMD5Message(connection.username, connection.password, connection._salt);

    connection._socket.add(authMessage.asBytes());

    return this;
  }

  _PostgreSQLConnectionState onMessage(_ServerMessage message) {
    if (message is _ParameterStatusMessage) {
      connection.settings[message.name] = message.value;
    } else if (message is _BackendKeyMessage) {
      connection._secretKey = message.secretKey;
      connection._processID = message.processID;
    } else if (message is _ReadyForQueryMessage) {
      if (message.state == _ReadyForQueryMessage.StateIdle) {
        return new _PostgreSQLConnectionStateIdle()
          ..pendingOperation = pendingOperation;
      }
    }

    return this;
  }
}

/*
  Authenticated state
 */

class _PostgreSQLConnectionStateAuthenticated extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionState queueQuery(_Query query) {
    throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
  }

  _PostgreSQLConnectionState onMessage(_ServerMessage message) {
    if (message is _ParameterStatusMessage) {
      connection.settings[message.name] = message.value;
    } else if (message is _BackendKeyMessage) {
      connection._secretKey = message.secretKey;
      connection._processID = message.processID;
    } else if (message is _ReadyForQueryMessage) {
      if (message.state == _ReadyForQueryMessage.StateIdle) {
        return new _PostgreSQLConnectionStateIdle()
          ..pendingOperation = pendingOperation;
      }
    }

    return this;
  }
}

/*
  Ready/idle state
 */

class _PostgreSQLConnectionStateIdle extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionState queueQuery(_Query q) {
    connection._queryQueue.add(q);

    return processQuery(q);
  }

  _PostgreSQLConnectionState processQuery(_Query q) {
    try {
      if (q.onlyReturnAffectedRowCount) {
        sendSimpleQuery(q);

        return new _PostgreSQLConnectionStateBusy(q);
      }

      var cache = sendExtendedQuery(q);

      return new _PostgreSQLConnectionStateBusy(q, cacheToBuild: cache);
    } catch (e, st) {
      q.onComplete.completeError(e, st);
      connection._queryQueue.remove(q);
    }

    // If there was an exception, try moving on to the next query.
    if (connection._queryQueue.isNotEmpty) {
      return processQuery(connection._queryQueue.first);
    }

    return this;
  }

  _PostgreSQLConnectionState onEnter() {
    // This is for waiters on 'open'. If not in the process of opening, then this just no-ops.
    completeWaitingEvent(null);

    if (connection._queryQueue.isNotEmpty) {
      return processQuery(connection._queryQueue.first);
    }

    return this;
  }

  _PostgreSQLConnectionState onMessage(_ServerMessage message) {
    return this;
  }

  void sendSimpleQuery(_Query q) {
    var sqlString = PostgreSQLFormat.substitute(q.statement, q.substitutionValues);
    var queryMessage = new _QueryMessage(sqlString);

    connection._socket.add(queryMessage.asBytes());
  }

  _QueryCache sendExtendedQuery(_Query q) {
    var cacheQuery = connection._reuseMap[q.statement];
    if (q.allowReuse && cacheQuery != null) {
      q.fieldDescriptions = cacheQuery.fieldDescriptions;
      executeCachedQuery(cacheQuery, q.substitutionValues);

      return null;
    }

    String statementName = (q.allowReuse ? connection._generateNextQueryIdentifier() : "");
    var formatIdentifiers = <_PostgreSQLFormatIdentifier>[];
    var replaceFunc = (_PostgreSQLFormatIdentifier identifier, int index) {
      formatIdentifiers.add(identifier);

      return "\$$index";
    };

    var sqlString = PostgreSQLFormat.substitute(q.statement, q.substitutionValues, replace: replaceFunc);
    q.specifiedParameterTypeCodes = formatIdentifiers.map((i) => i.typeCode).toList();
    var parameterList = formatIdentifiers
        .map((id) => encodeParameter(id, q.substitutionValues))
        .toList();

    var messages = [
      new _ParseMessage(sqlString, statementName: statementName),
      new _DescribeMessage(statementName: statementName),
      new _BindMessage(parameterList, statementName: statementName),
      new _ExecuteMessage(),
      new _SyncMessage()
    ];

    connection._socket.add(_ClientMessage.aggregateBytes(messages));

    return (q.allowReuse ? new _QueryCache(statementName, formatIdentifiers) :  null);
  }

  void executeCachedQuery(_QueryCache cacheQuery, Map<String, dynamic> substitutionValues) {
    var statementName = cacheQuery.preparedStatementName;
    var parameterList = cacheQuery.orderedParameters
        .map((identifier) => encodeParameter(identifier, substitutionValues))
        .toList();

    // We can both check known types and also convert them to binary in the Bind message now
    var bytes = _ClientMessage.aggregateBytes([
      new _BindMessage(parameterList, statementName: statementName),
      new _ExecuteMessage(),
      new _SyncMessage()
    ]);

    connection._socket.add(bytes);
  }

  _ParameterValue encodeParameter(_PostgreSQLFormatIdentifier identifier, Map<String, dynamic> substitutionValues) {
    if (identifier.typeCode != null) {
      return new _ParameterValue.binary(substitutionValues[identifier.name], identifier.typeCode);
    } else {
      return new _ParameterValue.text(substitutionValues[identifier.name]);
    }
  }
}

/*
  Busy state, query in progress
 */

class _PostgreSQLConnectionStateBusy extends _PostgreSQLConnectionState {
  _PostgreSQLConnectionStateBusy(this.query, {this.cacheToBuild: null});

  _Query query;
  _QueryCache cacheToBuild;
  PostgreSQLException returningException = null;
  int rowsAffected = 0;

  _PostgreSQLConnectionState onEnter() {
    pendingOperation = query.onComplete;
    return this;
  }

  _PostgreSQLConnectionState onErrorResponse(_ErrorResponseMessage message) {
    // If we get an error here, then we should eat the rest of the messages
    // and we are always confirmed to get a _ReadyForQueryMessage to finish up.
    // We should only report the error once that is done.
    var exception = new PostgreSQLException._(message.fields);

    if (exception.severity == PostgreSQLSeverity.fatal || exception.severity == PostgreSQLSeverity.panic) {
      return new _PostgreSQLConnectionStateClosed();
    }

    returningException ??= exception;

    return this;
  }

  _PostgreSQLConnectionState onMessage(_ServerMessage message) {
    // We ignore and NoData, as they don't tell us anything we don't already know
    // or care about.
    if (message is _ReadyForQueryMessage) {
      if (message.state == _ReadyForQueryMessage.StateIdle) {
        if (returningException != null) {
          query.completeError(returningException);
        } else {
          query.complete(rowsAffected);
        }

        return new _PostgreSQLConnectionStateIdle();
      }

      // Hmm?
    } else if (message is _CommandCompleteMessage) {
      rowsAffected = message.rowsAffected;
    } else if (message is _RowDescriptionMessage) {
      query.fieldDescriptions = message.fieldDescriptions;

      if (cacheToBuild != null && returningException == null) {
        cacheToBuild.fieldDescriptions = message.fieldDescriptions;
        connection._cacheQuery(query, cacheToBuild);
      }
    } else if (message is _DataRowMessage) {
      query.addRow(message.values);
    } else if (message is _ParameterDescriptionMessage) {
      var actualParameterTypeCodeIterator = message.parameterTypeIDs.iterator;
      var parametersAreMismatched = query.specifiedParameterTypeCodes.map((specifiedTypeCode) {
        actualParameterTypeCodeIterator.moveNext();
        return actualParameterTypeCodeIterator.current == (specifiedTypeCode ?? actualParameterTypeCodeIterator.current);
      }).any((v) => v == false);

      if (parametersAreMismatched) {
        returningException ??= new PostgreSQLException("Specified parameter types do not match column parameter types in query ${query.statement}");
      }
    }

    return this;
  }

  void onExit() {
    connection._queryQueue.remove(query);
  }
}