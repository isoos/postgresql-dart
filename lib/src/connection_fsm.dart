part of postgres;

abstract class PostgreSQLConnectionState {
  PostgreSQLConnection connection;
  Completer pendingOperation;

  PostgreSQLConnectionState queueQuery(_Query query) {
    connection._queryQueue.add(query);

    return this;
  }

  PostgreSQLConnectionState onErrorResponse(_ErrorResponseMessage message) {
    var exception = new PostgreSQLException._(message.fields);
    completeWaitingEvent(null, error: exception);

    if (exception.severity == PostgreSQLSeverity.fatal || exception.severity == PostgreSQLSeverity.panic) {
      return new PostgreSQLConnectionStateClosed();
    }

    return this;
  }

  PostgreSQLConnectionState onEnter() {
    return this;
  }

  PostgreSQLConnectionState onMessage(_ServerMessage message) {
    return this;
  }

  void onExit() {

  }

  void completeWaitingEvent(dynamic data, {dynamic error, StackTrace trace}) {
    var p = pendingOperation;
    pendingOperation = null;

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

class PostgreSQLConnectionStateClosed extends PostgreSQLConnectionState {
  PostgreSQLConnectionState queueQuery(_Query query) {
    throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
  }

  PostgreSQLConnectionState onMessage(_ServerMessage message) {
    return this;
  }
}

/*
  Socket connected, prior to any PostgreSQL handshaking - initiates that handshaking
 */

class PostgreSQLConnectionStateSocketConnected extends PostgreSQLConnectionState {
  PostgreSQLConnectionState queueQuery(_Query query) {
    throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
  }

  PostgreSQLConnectionState onEnter() {
    var startupMessage = new _StartupMessage(connection.databaseName, connection.timeZone, username: connection.username);

    connection._socket.add(startupMessage.asBytes());
    pendingOperation = new Completer();

    return this;
  }

  PostgreSQLConnectionState onMessage(_ServerMessage message) {
    _AuthenticationMessage authMessage = message;

    // Pass on the pending op to subsequent stages
    if (authMessage.type == _AuthenticationMessage.KindOK) {
      return new PostgreSQLConnectionStateAuthenticated()
          ..pendingOperation = pendingOperation;
    } else if (authMessage.type == _AuthenticationMessage.KindMD5Password) {
      connection._salt = authMessage.salt;

      return new PostgreSQLConnectionStateAuthenticating()
          ..pendingOperation = pendingOperation;
    }

    completeWaitingEvent(null, error: new PostgreSQLException("Unsupported authentication type ${authMessage.type}, closing connection."));

    return new PostgreSQLConnectionStateClosed();
  }
}

/*
  Authenticating state
 */

class PostgreSQLConnectionStateAuthenticating extends PostgreSQLConnectionState {
  PostgreSQLConnectionState queueQuery(_Query query) {
    throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
  }

  PostgreSQLConnectionState onEnter() {
    var authMessage = new _AuthMD5Message(connection.username, connection.password, connection._salt);

    connection._socket.add(authMessage.asBytes());

    return this;
  }

  PostgreSQLConnectionState onMessage(_ServerMessage message) {
    if (message is _ParameterStatusMessage) {
      connection.settings[message.name] = message.value;
    } else if (message is _BackendKeyMessage) {
      connection._secretKey = message.secretKey;
      connection._processID = message.processID;
    } else if (message is _ReadyForQueryMessage) {
      if (message.state == _ReadyForQueryMessage.StateIdle) {
        return new PostgreSQLConnectionStateIdle()
          ..pendingOperation = pendingOperation;
      }
    }

    return this;
  }
}

/*
  Authenticated state
 */

class PostgreSQLConnectionStateAuthenticated extends PostgreSQLConnectionState {
  PostgreSQLConnectionState queueQuery(_Query query) {
    throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
  }

  PostgreSQLConnectionState onMessage(_ServerMessage message) {
    if (message is _ParameterStatusMessage) {
      connection.settings[message.name] = message.value;
    } else if (message is _BackendKeyMessage) {
      connection._secretKey = message.secretKey;
      connection._processID = message.processID;
    } else if (message is _ReadyForQueryMessage) {
      if (message.state == _ReadyForQueryMessage.StateIdle) {
        return new PostgreSQLConnectionStateIdle()
          ..pendingOperation = pendingOperation;
      }
    }

    return this;
  }
}

/*
  Ready/idle state
 */

class PostgreSQLConnectionStateIdle extends PostgreSQLConnectionState {
  PostgreSQLConnectionState queueQuery(_Query q) {
    connection._queryQueue.add(q);

    return processQuery(q);
  }

  PostgreSQLConnectionState processQuery(_Query q) {
    try {
      if (q.onlyReturnAffectedRowCount) {
        sendSimpleQuery(q);
        return new PostgreSQLConnectionStateBusy(q);
      }

      var cache = sendExtendedQuery(q);
      return new PostgreSQLConnectionStateBusy(q, cacheToBuild: cache);
    } catch (e, st) {
      q.onComplete.completeError(e, st);
      connection._queryQueue.remove(q);
    }

    // If there was an exception, try moving on to the next query.
    if (connection._queryQueue.isNotEmpty) {
      return queueQuery(connection._queryQueue.first);
    }

    return this;
  }

  PostgreSQLConnectionState onEnter() {
    // This is for waiters on 'open'. If not in the process of opening, then this just no-ops.
    completeWaitingEvent(null);

    if (connection._queryQueue.isNotEmpty) {
      return processQuery(connection._queryQueue.first);
    }

    return this;
  }

  PostgreSQLConnectionState onMessage(_ServerMessage message) {
    return this;
  }

  void sendSimpleQuery(_Query q) {
    var sqlString = PostgreSQLFormat.substitute(q.statement, q.substitutionValues);
    var queryMessage = new _QueryMessage(sqlString);

    connection._socket.add(queryMessage.asBytes());
  }

  _QueryCache sendExtendedQuery(_Query q) {
    List<_ParameterValue> parameterList;
    _QueryCache toCache = null;
    String statementName = "";
    var messages = <_ClientMessage>[];

    var cacheQuery = connection._reuseMap[q.statement];
    if (q.allowReuse && cacheQuery != null) {
      q.fieldDescriptions = cacheQuery.fieldDescriptions;
      statementName = cacheQuery.preparedStatementName;
      parameterList = cacheQuery.orderedParameters
          .map((identifier) => encodeParameter(identifier, q.substitutionValues))
          .toList();
    } else {
      var formatIdentifiers = <PostgreSQLFormatIdentifier>[];
      var replaceFunc = (PostgreSQLFormatIdentifier identifier, int index) {
        formatIdentifiers.add(identifier);

        return "\$$index";
      };

      var sqlString = PostgreSQLFormat.substitute(q.statement, q.substitutionValues, replace: replaceFunc);
      parameterList = formatIdentifiers
          .map((id) => encodeParameter(id, q.substitutionValues))
          .toList();

      if (q.allowReuse) {
        statementName = connection._generateNextQueryIdentifier();
        toCache = new _QueryCache(statementName, formatIdentifiers);
      }
      messages.addAll([
        new _ParseMessage(sqlString, statementName: statementName),
        new _DescribeMessage(statementName: statementName),
      ]);
    }

    messages.addAll([
      new _BindMessage(parameterList, statementName: statementName),
      new _ExecuteMessage(),
      new _SyncMessage()
    ]);
    var bytes = _ClientMessage.aggregateBytes(messages);

    connection._socket.add(bytes);

    return toCache;
  }

  _ParameterValue encodeParameter(PostgreSQLFormatIdentifier identifier, Map<String, dynamic> substitutionValues) {
    if (identifier._dataType != null) {
      return new _ParameterValue.binary(substitutionValues[identifier.name], identifier.typeCode);
    } else {
      return new _ParameterValue.text(substitutionValues[identifier.name]);
    }
  }
}

/*
  Busy state, query in progress
 */

class PostgreSQLConnectionStateBusy extends PostgreSQLConnectionState {
  PostgreSQLConnectionStateBusy(this.query, {this.cacheToBuild: null});

  _Query query;
  _QueryCache cacheToBuild;

  PostgreSQLConnectionState onEnter() {
    pendingOperation = query.onComplete;
    return this;
  }

  PostgreSQLConnectionState onMessage(_ServerMessage message) {
    if (message is _ReadyForQueryMessage) {
      if (message.state == _ReadyForQueryMessage.StateIdle) {
        return new PostgreSQLConnectionStateIdle();
      }
    } else if (message is _CommandCompleteMessage) {
      query.finish(message.rowsAffected);
    } else if (message is _RowDescriptionMessage) {
      query.fieldDescriptions = message.fieldDescriptions;
      cacheToBuild?.fieldDescriptions = message.fieldDescriptions;
    } else if (message is _DataRowMessage) {
      query.addRow(message.values);
    }

    return this;
  }

  void onExit() {
    connection._queryQueue.remove(query);

    if (cacheToBuild != null) {
      connection.cacheQuery(query, cacheToBuild);
    }
  }
}

