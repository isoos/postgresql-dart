import 'utf8_backed_string.dart';
import 'dart:typed_data';
import 'query.dart';
import 'constants.dart';

import 'package:buffer/buffer.dart';
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

  void applyStringToBuffer(UTF8BackedString string, ByteDataWriter buffer) {
    buffer.write(string.utf8Bytes);
    buffer.writeInt8(0);
  }

  void applyBytesToBuffer(List<int> bytes, ByteDataWriter buffer) {
    buffer.write(bytes);
  }

  void applyToBuffer(ByteDataWriter buffer);

  Uint8List asBytes() {
    var buffer = new ByteDataWriter();
    applyToBuffer(buffer);
    return buffer.toBytes();
  }

  static Uint8List aggregateBytes(List<ClientMessage> messages) {
    var buffer = new ByteDataWriter();
    messages.forEach((cm) => cm.applyToBuffer(buffer));
    return buffer.toBytes();
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

  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeInt32(length);
    buffer.writeInt32(ClientMessage.ProtocolVersion);

    if (username != null) {
      applyBytesToBuffer((UTF8ByteConstants.user), buffer);
      applyStringToBuffer(username, buffer);
    }

    applyBytesToBuffer(UTF8ByteConstants.database, buffer);
    applyStringToBuffer(databaseName, buffer);

    applyBytesToBuffer(UTF8ByteConstants.clientEncoding, buffer);
    applyBytesToBuffer(UTF8ByteConstants.utf8, buffer);

    applyBytesToBuffer(UTF8ByteConstants.timeZone, buffer);
    applyStringToBuffer(timeZone, buffer);

    buffer.writeInt8(0);
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

  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.PasswordIdentifier);
    buffer.writeUint32(length - 1);
    applyStringToBuffer(hashedAuthString, buffer);
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

  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.QueryIdentifier);
    buffer.writeUint32(length - 1);
    applyStringToBuffer(queryString, buffer);
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

  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.ParseIdentifier);
    buffer.writeUint32(length - 1);
    // Name of prepared statement
    applyStringToBuffer(statementName, buffer);
    applyStringToBuffer(statement, buffer); // Query string
    buffer.writeUint16(0);
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

  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.DescribeIdentifier);
    buffer.writeUint32(length - 1);
    buffer.writeUint8(83);
    applyStringToBuffer(statementName, buffer); // Name of prepared statement
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

  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.BindIdentifier);
    buffer.writeUint32(length - 1);

    // Name of portal - currently unnamed portal.
    applyBytesToBuffer([0], buffer);
    // Name of prepared statement.
    applyStringToBuffer(statementName, buffer);

    // OK, if we have no specified types at all, we can use 0. If we have all specified types, we can use 1. If we have a mix, we have to individually
    // call out each type.
    if (typeSpecCount == parameters.length) {
      buffer.writeUint16(1);
      // Apply following format code for all parameters by indicating 1
      buffer.writeUint16(ClientMessage.FormatBinary);
    } else if (typeSpecCount == 0) {
      buffer.writeUint16(1);
      // Apply following format code for all parameters by indicating 1
      buffer.writeUint16(ClientMessage.FormatText);
    } else {
      // Well, we have some text and some binary, so we have to be explicit about each one
      buffer.writeUint16(parameters.length);
      parameters.forEach((p) {
        buffer.writeUint16(
            p.isBinary ? ClientMessage.FormatBinary : ClientMessage.FormatText);
      });
    }

    // This must be the number of $n's in the query.
    buffer.writeUint16(parameters.length);
    parameters.forEach((p) {
      if (p.bytes == null) {
        buffer.writeInt32(-1);
      } else {
        buffer.writeInt32(p.length);
        buffer.write(p.bytes);
      }
    });

    // Result columns - we always want binary for all of them, so specify 1:1.
    buffer.writeUint16(1);
    buffer.writeUint16(1);
  }
}

class ExecuteMessage extends ClientMessage {
  ExecuteMessage();

  int get length {
    return 10;
  }

  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.ExecuteIdentifier);
    buffer.writeUint32(length - 1);
    applyBytesToBuffer([0], buffer); // Portal name
    buffer.writeUint32(0);
  }
}

class SyncMessage extends ClientMessage {
  SyncMessage();

  int get length {
    return 5;
  }

  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.SyncIdentifier);
    buffer.writeUint32(4);
  }
}
