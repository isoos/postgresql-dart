import 'utf8_backed_string.dart';
import 'dart:typed_data';
import 'query.dart';
import 'constants.dart';
import 'package:crypto/crypto.dart';

abstract class ClientMessage {
  static const int FormatText = 0;
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

  int applyStringToBuffer(
      UTF8BackedString string, ByteData buffer, int offset) {
    var postStringOffset = string.utf8Bytes.fold(offset, (idx, unit) {
      buffer.setInt8(idx, unit);
      return idx + 1;
    });

    buffer.setInt8(postStringOffset, 0);
    return postStringOffset + 1;
  }

  int applyBytesToBuffer(List<int> bytes, ByteData buffer, int offset) {
    var postStringOffset = bytes.fold(offset, (idx, unit) {
      buffer.setInt8(idx, unit);
      return idx + 1;
    });

    return postStringOffset;
  }

  int applyToBuffer(ByteData aggregateBuffer, int offsetIntoAggregateBuffer);

  Uint8List asBytes() {
    var buffer = new ByteData(length);
    applyToBuffer(buffer, 0);
    return buffer.buffer.asUint8List();
  }

  static Uint8List aggregateBytes(List<ClientMessage> messages) {
    var totalLength =
        messages.fold(0, (total, ClientMessage next) => total + next.length);
    var buffer = new ByteData(totalLength);

    var offset = 0;
    messages.fold(
        offset, (inOffset, msg) => msg.applyToBuffer(buffer, inOffset));

    return buffer.buffer.asUint8List();
  }
}

class StartupMessage extends ClientMessage {
  StartupMessage(String databaseName, String timeZone, {String username}) {
    this.databaseName = new UTF8BackedString(databaseName);
    this.timeZone = new UTF8BackedString(timeZone);
    if (username != null) {
      this.username = new UTF8BackedString(username);
    }
  }

  UTF8BackedString username = null;
  UTF8BackedString databaseName;
  UTF8BackedString timeZone;

  ByteData buffer;

  int get length {
    var fixedLength = 53;
    var variableLength = (username?.utf8Length ?? 0) +
        databaseName.utf8Length +
        timeZone.utf8Length +
        3;

    return fixedLength + variableLength;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setInt32(offset, length);
    offset += 4;
    buffer.setInt32(offset, ClientMessage.ProtocolVersion);
    offset += 4;

    if (username != null) {
      offset = applyBytesToBuffer((UTF8ByteConstants.user), buffer, offset);
      offset = applyStringToBuffer(username, buffer, offset);
    }

    offset = applyBytesToBuffer(UTF8ByteConstants.database, buffer, offset);
    offset = applyStringToBuffer(databaseName, buffer, offset);

    offset =
        applyBytesToBuffer(UTF8ByteConstants.clientEncoding, buffer, offset);
    offset = applyBytesToBuffer(UTF8ByteConstants.utf8, buffer, offset);

    offset = applyBytesToBuffer(UTF8ByteConstants.timeZone, buffer, offset);
    offset = applyStringToBuffer(timeZone, buffer, offset);

    buffer.setInt8(offset, 0);
    offset += 1;

    return offset;
  }
}

class AuthMD5Message extends ClientMessage {
  AuthMD5Message(String username, String password, List<int> saltBytes) {
    var passwordHash =
        md5.convert("${password}${username}".codeUnits).toString();
    var saltString = new String.fromCharCodes(saltBytes);
    hashedAuthString = new UTF8BackedString(
        "md5" + md5.convert("$passwordHash$saltString".codeUnits).toString());
  }

  UTF8BackedString hashedAuthString;

  int get length {
    return 6 + hashedAuthString.utf8Length;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setUint8(offset, ClientMessage.PasswordIdentifier);
    offset += 1;
    buffer.setUint32(offset, length - 1);
    offset += 4;
    offset = applyStringToBuffer(hashedAuthString, buffer, offset);

    return offset;
  }
}

class QueryMessage extends ClientMessage {
  QueryMessage(String queryString) {
    this.queryString = new UTF8BackedString(queryString);
  }

  UTF8BackedString queryString;

  int get length {
    return 6 + queryString.utf8Length;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setUint8(offset, ClientMessage.QueryIdentifier);
    offset += 1;
    buffer.setUint32(offset, length - 1);
    offset += 4;
    offset = applyStringToBuffer(queryString, buffer, offset);

    return offset;
  }
}

class ParseMessage extends ClientMessage {
  ParseMessage(String statement, {String statementName: ""}) {
    this.statement = new UTF8BackedString(statement);
    this.statementName = new UTF8BackedString(statementName);
  }

  UTF8BackedString statementName;
  UTF8BackedString statement;

  int get length {
    return 9 + statement.utf8Length + statementName.utf8Length;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setUint8(offset, ClientMessage.ParseIdentifier);
    offset += 1;
    buffer.setUint32(offset, length - 1);
    offset += 4;
    // Name of prepared statement
    offset = applyStringToBuffer(statementName, buffer, offset);
    offset = applyStringToBuffer(statement, buffer, offset); // Query string
    buffer.setUint16(offset, 0);
    // Specifying types - may add this in the future, for now indicating we want the backend to infer.
    offset += 2;

    return offset;
  }
}

class DescribeMessage extends ClientMessage {
  DescribeMessage({String statementName: ""}) {
    this.statementName = new UTF8BackedString(statementName);
  }

  UTF8BackedString statementName;

  int get length {
    return 7 + statementName.utf8Length;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setUint8(offset, ClientMessage.DescribeIdentifier);
    offset += 1;
    buffer.setUint32(offset, length - 1);
    offset += 4;
    buffer.setUint8(offset, 83);
    offset += 1; // Indicate we are referencing a prepared statement
    offset = applyStringToBuffer(
        statementName, buffer, offset); // Name of prepared statement

    return offset;
  }
}

class BindMessage extends ClientMessage {
  BindMessage(this.parameters, {String statementName: ""}) {
    typeSpecCount = parameters.where((p) => p.isBinary).length;
    this.statementName = new UTF8BackedString(statementName);
  }

  List<ParameterValue> parameters;
  UTF8BackedString statementName;

  int typeSpecCount;
  int _cachedLength;

  int get length {
    if (_cachedLength == null) {
      var inputParameterElementCount = parameters.length;
      if (typeSpecCount == parameters.length || typeSpecCount == 0) {
        inputParameterElementCount = 1;
      }

      _cachedLength = 15;
      _cachedLength += statementName.utf8Length;
      _cachedLength += inputParameterElementCount * 2;
      _cachedLength += parameters.fold(0, (len, ParameterValue paramValue) {
        if (paramValue.bytes == null) {
          return len + 4;
        } else {
          return len + 4 + paramValue.length;
        }
      });
    }
    return _cachedLength;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setUint8(offset, ClientMessage.BindIdentifier);
    offset += 1;
    buffer.setUint32(offset, length - 1);
    offset += 4;

    // Name of portal - currently unnamed portal.
    offset = applyBytesToBuffer([0], buffer, offset);
    // Name of prepared statement.
    offset = applyStringToBuffer(statementName, buffer, offset);

    // OK, if we have no specified types at all, we can use 0. If we have all specified types, we can use 1. If we have a mix, we have to individually
    // call out each type.
    if (typeSpecCount == parameters.length) {
      buffer.setUint16(offset, 1);
      // Apply following format code for all parameters by indicating 1
      offset += 2;
      buffer.setUint16(offset, ClientMessage.FormatBinary);
      offset += 2; // Specify format code for all params is BINARY
    } else if (typeSpecCount == 0) {
      buffer.setUint16(offset, 1);
      // Apply following format code for all parameters by indicating 1
      offset += 2;
      buffer.setUint16(offset, ClientMessage.FormatText);
      offset += 2; // Specify format code for all params is TEXT
    } else {
      // Well, we have some text and some binary, so we have to be explicit about each one
      buffer.setUint16(offset, parameters.length);
      offset += 2;
      parameters.forEach((p) {
        buffer.setUint16(offset,
            p.isBinary ? ClientMessage.FormatBinary : ClientMessage.FormatText);
        offset += 2;
      });
    }

    // This must be the number of $n's in the query.
    buffer.setUint16(offset, parameters.length);
    offset += 2; // Number of parameters specified by query
    parameters.forEach((p) {
      if (p.bytes == null) {
        buffer.setInt32(offset, -1);
        offset += 4;
      } else {
        buffer.setInt32(offset, p.length);
        offset += 4;

        offset = p.bytes.fold(offset, (inOffset, byte) {
          buffer.setUint8(inOffset, byte);
          return inOffset + 1;
        });
      }
    });

    // Result columns - we always want binary for all of them, so specify 1:1.
    buffer.setUint16(offset, 1);
    offset += 2; // Apply format code for all result values by indicating 1
    buffer.setUint16(offset, 1);
    offset += 2; // Specify format code for all result values in binary

    return offset;
  }
}

class ExecuteMessage extends ClientMessage {
  ExecuteMessage();

  int get length {
    return 10;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setUint8(offset, ClientMessage.ExecuteIdentifier);
    offset += 1;
    buffer.setUint32(offset, length - 1);
    offset += 4;
    offset = applyBytesToBuffer([0], buffer, offset); // Portal name
    buffer.setUint32(offset, 0);
    offset += 4; // Row limit

    return offset;
  }
}

class SyncMessage extends ClientMessage {
  SyncMessage();

  int get length {
    return 5;
  }

  int applyToBuffer(ByteData buffer, int offset) {
    buffer.setUint8(offset, ClientMessage.SyncIdentifier);
    offset += 1;
    buffer.setUint32(offset, 4);
    offset += 4;
    return offset;
  }
}
