part of postgres;

abstract class _ClientMessage {
  static const int FormatText = 1;
  static const int FormatBinary = 1;

  static const int ProtocolVersion = 196608;

  static const int BindIdentifier = 66;
  static const int DescribeIdentifier = 68;
  static const int ExecuteIdentifier = 69;
  static const int ParseIdentifier = 80;
  static const int QueryIdentifier = 81;
  static const int SyncIdentifier = 83;
  static const int PasswordIdentifier = 112;

  int get length;

  int applyStringToBuffer(String string, ByteData buffer, int offset) {
    var postStringOffset = string.codeUnits.fold(offset, (idx, unit) {
      buffer.setInt8(idx, unit);
      return idx + 1;
    });

    buffer.setInt8(postStringOffset, 0);
    return postStringOffset + 1;
  }

  int applyToBuffer(ByteData aggregateBuffer, int offsetIntoAggregateBuffer);

  Uint8List asBytes() {
    var buffer = new ByteData(length);
    applyToBuffer(buffer, 0);
    return buffer.buffer.asUint8List();
  }

  static Uint8List aggregateBytes(List<_ClientMessage> messages) {
    var totalLength = messages.fold(0, (total, next) => total + next);
    var buffer = new ByteData(totalLength);

    var offset = 0;
    messages.fold(offset, (inOffset, msg) => msg.applyToBuffer(buffer, inOffset));
    return buffer.buffer.asUint8List();
  }
}

class _StartupMessage extends _ClientMessage {
  _StartupMessage(this.databaseName, this.timeZone, {this.username});

  String username = null;
  String databaseName;
  String timeZone;

  ByteData buffer;

  int get length {
    var fixedLength = 53;
    var variableLength = (username?.length ?? 0)
        + databaseName.length
        + timeZone.length + 3;

    return fixedLength + variableLength;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setInt32(offset, length); offset += 4;
    buffer.setInt32(offset, _ClientMessage.ProtocolVersion); offset += 4;

    if (username != null) {
      offset = applyStringToBuffer("user", buffer, offset);
      offset = applyStringToBuffer(username, buffer, offset);
    }

    offset = applyStringToBuffer("database", buffer, offset);
    offset = applyStringToBuffer(databaseName, buffer, offset);

    offset = applyStringToBuffer("client_encoding", buffer, offset);
    offset = applyStringToBuffer("UTF8", buffer, offset);

    offset = applyStringToBuffer("TimeZone", buffer, offset);
    offset = applyStringToBuffer(timeZone, buffer, offset);

    buffer.setInt8(offset, 0); offset += 1;

    return offset;
  }
}

class _AuthMD5Message extends _ClientMessage {
  _AuthMD5Message(String username, String password, List<int> saltBytes) {
    var passwordHash = md5.convert("${password}${username}".codeUnits).toString();
    var saltString = new String.fromCharCodes(saltBytes);
    hashedAuthString = "md5" + md5.convert("$passwordHash$saltString".codeUnits).toString();
  }

  String hashedAuthString;

  int get length {
    return 6 + hashedAuthString.length;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setUint8(offset, _ClientMessage.PasswordIdentifier); offset += 1;
    buffer.setUint32(offset, length - 1); offset += 4;
    offset = applyStringToBuffer(hashedAuthString, buffer, offset);

    return offset;
  }
}

class _QueryMessage extends _ClientMessage {
  _QueryMessage(this.queryString);

  String queryString;

  int get length {
    return 6 + queryString.length;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setUint8(offset, _ClientMessage.QueryIdentifier); offset += 1;
    buffer.setUint32(offset, length - 1); offset += 4;
    offset = applyStringToBuffer(queryString, buffer, offset);

    return offset;
  }
}

class _ParseMessage extends _ClientMessage {
  _ParseMessage (this.statement, {this.statementName});

  String statementName = "";
  String statement;

  int get length {
    return 8 + statement.length + statementName.length;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setUint8(offset, _ClientMessage.ParseIdentifier); offset += 1;
    buffer.setUint32(offset, length - 1); offset += 4;
    offset = applyStringToBuffer(statementName, buffer, offset); // Name of prepared statement
    offset = applyStringToBuffer(statement, buffer, offset); // Query string
    buffer.setUint16(offset, 0); offset += 2; // Specifying types - may add this in the future, for now indicating we want the backend to infer.

    return offset;
  }
}

class _DescribeMessage extends _ClientMessage {
  _DescribeMessage({this.statementName});

  String statementName = "";

  int get length {
    return 6 + statementName.length;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setUint8(offset, _ClientMessage.DescribeIdentifier); offset += 1;
    buffer.setUint32(offset, length - 1); offset += 4;
    buffer.setUint8(offset, 83); offset += 1; // Indicate we are referencing a prepared statement
    offset = applyStringToBuffer(statementName, buffer, offset); // Name of prepared statement

    return offset;
  }
}

class _BindMessage extends _ClientMessage {
  _BindMessage(this.parameters, {this.statementName});

  List<_ParameterValue> parameters;
  String statementName = "";

  int _cachedLength;
  int get length {
    if (_cachedLength == null) {
      _cachedLength = 0;
    }
    return _cachedLength;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setUint8(offset, _ClientMessage.BindIdentifier); offset += 1;
    buffer.setUint32(offset, length - 1); offset += 4;

    offset = applyStringToBuffer("", buffer, offset); // Name of portal - currently unnamed portal.
    offset = applyStringToBuffer(statementName, buffer, offset); // Name of prepared statement.

    // OK, if we have no specified types at all, we can use 0. If we have all specified types, we can use 1. If we have a mix, we have to individually
    // call out each type.
    var typeSpecCount = parameters.where((p) => p.isBinary).length;
    if (typeSpecCount == parameters.length) {
      buffer.setUint16(offset, _ClientMessage.FormatBinary); offset += 2; // Apply following format code for all parameters by indicating 1
      buffer.setUint16(offset, 1); offset += 2; // Specify format code for all params is BINARY
    } else if (typeSpecCount == 0) {
      buffer.setUint16(offset, 1); offset += 2; // Apply following format code for all parameters by indicating 1
      buffer.setUint16(offset, _ClientMessage.FormatText); offset += 2; // Specify format code for all params is TEXT
    } else {
      // Well, we have some text and some binary, so we have to be explicit about each one
      buffer.setUint16(offset, parameters.length); offset += 2;
      parameters.forEach((p) {
        buffer.setUint16(offset, p.isBinary ? _ClientMessage.FormatBinary : _ClientMessage.FormatText); offset += 2;
      });
    }

    // This must be the number of $n's in the query.
    buffer.setUint16(offset, parameters.length); offset += 2; // Number of parameters specified by query
    parameters.forEach((p) {
      buffer.setUint32(offset, p.length); offset += 4;
      offset = p.bytes.fold(offset, (inOffset, byte) {
        buffer.setUint8(inOffset, byte);
        return inOffset + 1;
      });
    });

    // Result columns - we always want binary for all of them, so specify 1:1.
    buffer.setUint16(offset, 1); offset += 2; // Apply format code for all result values by indicating 1
    buffer.setUint16(offset, 1); offset += 2; // Specify format code for all result values in binary

    return offset;
  }
}

class _ExecuteMessage extends _ClientMessage {
  _ExecuteMessage();

  int get length {
    return 11;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setUint8(offset, _ClientMessage.ExecuteIdentifier); offset += 1;
    buffer.setUint32(offset, length - 1); offset += 4;
    offset = applyStringToBuffer("", buffer, offset); // Portal name
    buffer.setUint32(offset, 0); offset += 4; // Row limit

    return offset;
  }
}

class _SyncMessage extends _ClientMessage {
  _SyncMessage();

  int get length {
    return 5;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setUint8(offset, _ClientMessage.SyncIdentifier); offset += 1;
    buffer.setUint32(offset, 4); offset += 4;
    return offset;
  }
}