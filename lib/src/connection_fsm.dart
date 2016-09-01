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

// Parse, Describe, Bind, Exec, Sync altogether
    var paramCount = 0;

    var parseLength = 8 + q.statement.length;
    var describeLength = 1 + 5; // The +1 is the prepared statement name
    var bindLength = 1 + 1 + 14 + 4 * paramCount; // The 1 + 1 are for the empty strings for specifying no portal and no prepared statement
    var execLength = 8 + 1; // The 1 is the name of the portal as empty string
    var syncLength = 4;
    var buffer = new ByteData(5 + parseLength + describeLength + bindLength + execLength + syncLength);

    var offset = 0;

    // Parse
    buffer.setUint8(offset, PostgreSQLConnection.ParseIdentifier); offset += 1;
    buffer.setUint32(offset, parseLength); offset += 4;
    offset = _applyStringToBuffer("", buffer, offset); // Name of prepared statement
    offset = _applyStringToBuffer(q.statement, buffer, offset); // Query string
    buffer.setUint16(offset, 0); offset += 2; // Specifying types - may add this in the future, for now indicating we want the backend to infer.

    // Describe
    buffer.setUint8(offset, PostgreSQLConnection.DescribeIdentifier); offset += 1;
    buffer.setUint32(offset, describeLength); offset += 4;
    buffer.setUint8(offset, 83); offset += 1;
    offset = _applyStringToBuffer("", buffer, offset); // Name of prepared statement

    // Bind
    buffer.setUint8(offset, PostgreSQLConnection.BindIdentifier); offset += 1;
    buffer.setUint32(offset, bindLength); offset += 4;
    offset = _applyStringToBuffer("", buffer, offset); // Name of portal - currently unnamed portal.
    offset = _applyStringToBuffer("", buffer, offset); // Name of prepared statement.
    buffer.setUint16(offset, 1); offset += 2; // Apply format code for all parameters by indicating 1
    buffer.setUint16(offset, 1); offset += 2; // Specify format code for all params in binary
    buffer.setUint16(offset, 0); offset += 2; // Number of parameters specified by query
    // for each param, length of param value and value un binary
    buffer.setUint16(offset, 1); offset += 2; // Apply format code for all result values by indicating 1
    buffer.setUint16(offset, 1); offset += 2; // Specify format code for all result values in binary

    // Exec
    buffer.setUint8(offset, PostgreSQLConnection.ExecuteIdentifier); offset += 1;
    buffer.setUint32(offset, execLength); offset += 4;
    offset = _applyStringToBuffer("", buffer, offset); // Portal name
    buffer.setUint32(offset, 0); offset += 4; // Row limit

    // Sync
    buffer.setUint8(offset, PostgreSQLConnection.SyncIdentifier); offset += 1;
    buffer.setUint32(offset, 4); offset += 4;

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

