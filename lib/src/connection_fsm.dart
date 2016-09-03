part of postgres;

abstract class PostgreSQLConnectionState {
  PostgreSQLConnection connection;

  PostgreSQLConnectionState executeQuery(_SQLQuery query) {
    connection._queryQueue.add(query);
    return this;
  }

  PostgreSQLConnectionState onErrorResponse(_ServerMessage message) {
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
}

/*
  Closed State; starts here and ends here.
 */

class PostgreSQLConnectionStateClosed extends PostgreSQLConnectionState {
}

/*
  Socket connected, prior to any PostgreSQL handshaking - initiates that handshaking
 */

class PostgreSQLConnectionStateSocketConnected extends PostgreSQLConnectionState {
  PostgreSQLConnectionState onEnter() {
    var startupMessage = new _StartupMessage(connection.databaseName, connection.timeZone, username: connection.username);

    connection._socket.add(startupMessage.asBytes());

    return this;
  }

  PostgreSQLConnectionState onMessage(_ServerMessage message) {
    _AuthenticationMessage authMessage = message;

    if (authMessage.type == _AuthenticationMessage.KindOK) {
      return new PostgreSQLConnectionStateAuthenticated();
    } else if (authMessage.type == _AuthenticationMessage.KindMD5Password) {
      connection._salt = authMessage.salt;
      return new PostgreSQLConnectionStateAuthenticating();
    }

    throw new PostgreSQLConnectionException("Unsupported authentication mechanism ${authMessage.type}");
  }
}

/*
  Authenticating state
 */

class PostgreSQLConnectionStateAuthenticating extends PostgreSQLConnectionState {
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
        return new PostgreSQLConnectionStateIdle();
      }
    }

    return this;
  }
}

/*
  Authenticated state
 */

class PostgreSQLConnectionStateAuthenticated extends PostgreSQLConnectionState {
  PostgreSQLConnectionState onMessage(_ServerMessage message) {
    if (message is _ParameterStatusMessage) {
      connection.settings[message.name] = message.value;
    } else if (message is _BackendKeyMessage) {
      connection._secretKey = message.secretKey;
      connection._processID = message.processID;
    } else if (message is _ReadyForQueryMessage) {
      if (message.state == _ReadyForQueryMessage.StateIdle) {
        return new PostgreSQLConnectionStateIdle();
      }
    }

    return this;
  }
}

/*
  Ready/idle state
 */

class PostgreSQLConnectionStateIdle extends PostgreSQLConnectionState {
  PostgreSQLConnectionState executeQuery(_SQLQuery q) {
    connection._queryQueue.add(q);

    if (q.onlyReturnAffectedRowCount) {
      sendSimpleQuery(q);
    } else {
      sendExtendedQuery(q);
    }

    return new PostgreSQLConnectionStateBusy();
  }

  PostgreSQLConnectionState onEnter() {
    connection._connectionFinishedOpening?.complete();
    connection._connectionFinishedOpening = null;

    if (connection._queryQueue.isNotEmpty) {
      return executeQuery(connection._queryQueue.first);
    }

    return this;
  }

  PostgreSQLConnectionState onMessage(_ServerMessage message) {
    return this;
  }

  void sendSimpleQuery(_SQLQuery q) {
    var sqlString = PostgreSQLFormat.substitute(q.statement, q.substitutionValues);
    var queryMessage = new _QueryMessage(sqlString);

    connection._socket.add(queryMessage.asBytes());
  }

  void sendExtendedQuery(_SQLQuery q) {
    var parameterList = <_ParameterValue>[];
    var replaceFunc = (String identifier, int index, String dataTypeSpecifier) {
      parameterList.add(q.substitutionValues[identifier]);

      return "\$$index";
    };

    var sqlString = PostgreSQLFormat.substitute(q.statement, q.substitutionValues, replace: replaceFunc);
    var bytes = _ClientMessage.aggregateBytes([
      new _ParseMessage(sqlString),
      new _DescribeMessage(),
      new _BindMessage(parameterList),
      new _ExecuteMessage(),
      new _SyncMessage()
    ]);

    connection._socket.add(bytes);
  }
}

/*
  Busy state, query in progress
 */

class PostgreSQLConnectionStateBusy extends PostgreSQLConnectionState {
  PostgreSQLConnectionState onErrorResponse(_ServerMessage message) {
    _ErrorResponseMessage msg = message;
    return this;
  }

  PostgreSQLConnectionState onMessage(_ServerMessage message) {
    if (message is _ReadyForQueryMessage) {
      if (message.state == _ReadyForQueryMessage.StateIdle) {
        return new PostgreSQLConnectionStateIdle();
      }
    } else if (message is _CommandCompleteMessage) {
      connection._queryInTransit.finish(message.rowsAffected);
    } else if (message is _RowDescriptionMessage) {
      connection._queryInTransit.fieldDescriptions = message.fieldDescriptions;
    } else if (message is _DataRowMessage) {
      connection._queryInTransit.addRow(message.values);
    }

    return this;
  }

  void onExit() {
    connection._queryQueue.removeAt(0);
  }
}

