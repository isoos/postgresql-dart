part of postgres;

abstract class PostgreSQLConnectionState {
  PostgreSQLConnection connection;

  PostgreSQLConnectionState executeQuery(_SQLQuery query) {
    connection._queryQueue.add(query);
    return this;
  }

  PostgreSQLConnectionState onErrorResponse(_Message message) {
    return this;
  }

  PostgreSQLConnectionState onEnter() {
    return this;
  }

  PostgreSQLConnectionState onMessage(_Message message) {
    return this;
  }

  void onExit() {

  }
}

class PostgreSQLConnectionStateClosed extends PostgreSQLConnectionState {
  PostgreSQLConnectionState onEnter() {
    connection._cleanup();

    return this;
  }
}

class PostgreSQLConnectionStateSocketConnected extends PostgreSQLConnectionState {

  PostgreSQLConnectionState onEnter() {
    var variableLength = (connection.username?.length ?? 0)
        + connection.databaseName.length
        + connection.timeZone.length + 3;
    var fixedLength = 53;

    var buffer = new ByteData(fixedLength + variableLength);
    var offset = 0;
    buffer.setInt32(offset, fixedLength + variableLength); offset += 4;
    buffer.setInt32(offset, PostgreSQLConnection.ProtocolVersion); offset += 4;

    if (connection.username != null) {
      offset = _applyStringToBuffer("user", buffer, offset);
      offset = _applyStringToBuffer(connection.username, buffer, offset);
    }
    offset = _applyStringToBuffer("database", buffer, offset);
    offset = _applyStringToBuffer(connection.databaseName, buffer, offset);

    offset = _applyStringToBuffer("client_encoding", buffer, offset);
    offset = _applyStringToBuffer("UTF8", buffer, offset);

    offset = _applyStringToBuffer("TimeZone", buffer, offset);
    offset = _applyStringToBuffer(connection.timeZone, buffer, offset);

    buffer.setInt8(offset, 0); offset += 1;

    connection._socket.add(buffer.buffer.asUint8List());

    return this;
  }

  PostgreSQLConnectionState onMessage(_Message message) {
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

class PostgreSQLConnectionStateAuthenticating extends PostgreSQLConnectionState {
  PostgreSQLConnectionState onEnter() {
    // Send auth message
    var passwordHash = md5.convert("${connection.password}${connection.username}".codeUnits).toString();
    var salt = new String.fromCharCodes(connection._salt);
    var hashedAuth = "md5" + md5.convert("$passwordHash$salt".codeUnits).toString();

    var buffer = new ByteData(6 + hashedAuth.length);
    var offset = 0;

    buffer.setUint8(offset, PostgreSQLConnection.PasswordIdentifier); offset += 1;
    buffer.setUint32(offset, hashedAuth.length + 5); offset += 4;
    offset = _applyStringToBuffer(hashedAuth, buffer, offset);

    connection._socket.add(buffer.buffer.asUint8List());

    return this;
  }

  PostgreSQLConnectionState onMessage(_Message message) {
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

class PostgreSQLConnectionStateAuthenticated extends PostgreSQLConnectionState {
  PostgreSQLConnectionState onMessage(_Message message) {

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

class PostgreSQLConnectionStateIdle extends PostgreSQLConnectionState {
  PostgreSQLConnectionState executeQuery(_SQLQuery q) {
    connection._queryQueue.add(q);

    var buffer = new ByteData(6 + q.statement.length);
    var offset = 0;

    buffer.setUint8(offset, PostgreSQLConnection.QueryIdentifier); offset += 1;
    buffer.setUint32(offset, q.statement.length + 5); offset += 4;
    offset = _applyStringToBuffer(q.statement, buffer, offset);

    connection._socket.add(buffer.buffer.asUint8List());

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

  PostgreSQLConnectionState onMessage(_Message message) {
    return this;
  }
}

class PostgreSQLConnectionStateBusy extends PostgreSQLConnectionState {
  PostgreSQLConnectionState onMessage(_Message message) {

    if (message is _ReadyForQueryMessage) {
      if (message.state == _ReadyForQueryMessage.StateIdle) {
        return new PostgreSQLConnectionStateIdle();
      }
    } else if (message is _CommandCompleteMessage) {
      connection._queryInTransit.finish();
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

