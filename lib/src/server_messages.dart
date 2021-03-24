import 'dart:convert';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import 'connection.dart';
import 'query.dart';

abstract class ServerMessage {}

class ErrorResponseMessage implements ServerMessage {
  final fields = <ErrorField>[];

  ErrorResponseMessage(Uint8List bytes) {
    final reader = ByteDataReader()..add(bytes);

    int? identificationToken;
    StringBuffer? sb;

    while (reader.remainingLength > 0) {
      final byte = reader.readUint8();
      if (identificationToken == null) {
        identificationToken = byte;
        sb = StringBuffer();
      } else if (byte == 0) {
        fields.add(ErrorField(identificationToken, sb.toString()));
        identificationToken = null;
        sb = null;
      } else {
        sb!.writeCharCode(byte);
      }
    }
    if (identificationToken != null && sb != null) {
      fields.add(ErrorField(identificationToken, sb.toString()));
    }
  }
}

class AuthenticationMessage implements ServerMessage {
  static const int KindOK = 0;
  static const int KindKerberosV5 = 2;
  static const int KindClearTextPassword = 3;
  static const int KindMD5Password = 5;
  static const int KindSCMCredential = 6;
  static const int KindGSS = 7;
  static const int KindGSSContinue = 8;
  static const int KindSSPI = 9;

  final int type;
  final List<int> salt;

  AuthenticationMessage._(this.type, this.salt);

  factory AuthenticationMessage(Uint8List bytes) {
    final reader = ByteDataReader()..add(bytes);
    final type = reader.readUint32();
    final salt = <int>[];
    if (type == KindMD5Password) {
      salt.addAll(reader.read(4, copy: true));
    }
    return AuthenticationMessage._(type, salt);
  }
}

class ParameterStatusMessage extends ServerMessage {
  final String name;
  final String value;

  ParameterStatusMessage._(this.name, this.value);

  factory ParameterStatusMessage(Uint8List bytes) {
    final first0 = bytes.indexOf(0);
    final name = utf8.decode(bytes.sublist(0, first0));
    final value = utf8.decode(bytes.sublist(first0 + 1, bytes.lastIndexOf(0)));
    return ParameterStatusMessage._(name, value);
  }
}

class ReadyForQueryMessage extends ServerMessage {
  static const String StateIdle = 'I';
  static const String StateTransaction = 'T';
  static const String StateTransactionError = 'E';

  final String state;

  ReadyForQueryMessage(Uint8List bytes) : state = utf8.decode(bytes);
}

class BackendKeyMessage extends ServerMessage {
  final int processID;
  final int secretKey;

  BackendKeyMessage._(this.processID, this.secretKey);

  factory BackendKeyMessage(Uint8List bytes) {
    final view = ByteData.view(bytes.buffer, bytes.offsetInBytes);
    final processID = view.getUint32(0);
    final secretKey = view.getUint32(4);
    return BackendKeyMessage._(processID, secretKey);
  }
}

class RowDescriptionMessage extends ServerMessage {
  final fieldDescriptions = <FieldDescription>[];

  RowDescriptionMessage(Uint8List bytes) {
    final reader = ByteDataReader()..add(bytes);
    final fieldCount = reader.readInt16();

    for (var i = 0; i < fieldCount; i++) {
      final rowDesc = FieldDescription.read(reader);
      fieldDescriptions.add(rowDesc);
    }
  }
}

class DataRowMessage extends ServerMessage {
  final values = <Uint8List?>[];

  DataRowMessage(Uint8List bytes) {
    final reader = ByteDataReader()..add(bytes);
    final fieldCount = reader.readInt16();

    for (var i = 0; i < fieldCount; i++) {
      final dataSize = reader.readInt32();

      if (dataSize == 0) {
        values.add(Uint8List(0));
      } else if (dataSize == -1) {
        values.add(null);
      } else {
        final rawBytes = reader.read(dataSize);
        values.add(rawBytes);
      }
    }
  }

  @override
  String toString() => 'Data Row Message: $values';
}

class NotificationResponseMessage extends ServerMessage {
  final int processID;
  final String channel;
  final String payload;

  NotificationResponseMessage._(this.processID, this.channel, this.payload);

  factory NotificationResponseMessage(Uint8List bytes) {
    final view = ByteData.view(bytes.buffer, bytes.offsetInBytes);
    final processID = view.getUint32(0);
    final first0 = bytes.indexOf(0, 4);
    final channel = utf8.decode(bytes.sublist(4, first0));
    final payload =
        utf8.decode(bytes.sublist(first0 + 1, bytes.lastIndexOf(0)));
    return NotificationResponseMessage._(processID, channel, payload);
  }
}

class CommandCompleteMessage extends ServerMessage {
  final int rowsAffected;

  static RegExp identifierExpression = RegExp(r'[A-Z ]*');

  CommandCompleteMessage._(this.rowsAffected);

  factory CommandCompleteMessage(Uint8List bytes) {
    final str = utf8.decode(bytes.sublist(0, bytes.length - 1));
    final match = identifierExpression.firstMatch(str);
    var rowsAffected = 0;
    if (match != null && match.end < str.length) {
      rowsAffected = int.parse(str.split(' ').last);
    }
    return CommandCompleteMessage._(rowsAffected);
  }
}

class ParseCompleteMessage extends ServerMessage {
  ParseCompleteMessage();

  @override
  String toString() => 'Parse Complete Message';
}

class BindCompleteMessage extends ServerMessage {
  BindCompleteMessage();

  @override
  String toString() => 'Bind Complete Message';
}

class ParameterDescriptionMessage extends ServerMessage {
  final parameterTypeIDs = <int>[];

  ParameterDescriptionMessage(Uint8List bytes) {
    final reader = ByteDataReader()..add(bytes);
    final count = reader.readUint16();

    for (var i = 0; i < count; i++) {
      parameterTypeIDs.add(reader.readUint32());
    }
  }
}

class NoDataMessage extends ServerMessage {
  NoDataMessage();

  @override
  String toString() => 'No Data Message';
}

class UnknownMessage extends ServerMessage {
  final int? code;
  final Uint8List? bytes;

  UnknownMessage(this.code, this.bytes);

  @override
  int get hashCode {
    return bytes.hashCode;
  }

  @override
  bool operator ==(dynamic other) {
    if (bytes != null) {
      if (bytes!.length != other.bytes.length) {
        return false;
      }
      for (var i = 0; i < bytes!.length; i++) {
        if (bytes![i] != other.bytes[i]) {
          return false;
        }
      }
    } else {
      if (other.bytes != null) {
        return false;
      }
    }
    return code == other.code;
  }
}

class ErrorField {
  static const int SeverityIdentifier = 83;
  static const int CodeIdentifier = 67;
  static const int MessageIdentifier = 77;
  static const int DetailIdentifier = 68;
  static const int HintIdentifier = 72;
  static const int PositionIdentifier = 80;
  static const int InternalPositionIdentifier = 112;
  static const int InternalQueryIdentifier = 113;
  static const int WhereIdentifier = 87;
  static const int SchemaIdentifier = 115;
  static const int TableIdentifier = 116;
  static const int ColumnIdentifier = 99;
  static const int DataTypeIdentifier = 100;
  static const int ConstraintIdentifier = 110;
  static const int FileIdentifier = 70;
  static const int LineIdentifier = 76;
  static const int RoutineIdentifier = 82;

  static PostgreSQLSeverity severityFromString(String? str) {
    switch (str) {
      case 'ERROR':
        return PostgreSQLSeverity.error;
      case 'FATAL':
        return PostgreSQLSeverity.fatal;
      case 'PANIC':
        return PostgreSQLSeverity.panic;
      case 'WARNING':
        return PostgreSQLSeverity.warning;
      case 'NOTICE':
        return PostgreSQLSeverity.notice;
      case 'DEBUG':
        return PostgreSQLSeverity.debug;
      case 'INFO':
        return PostgreSQLSeverity.info;
      case 'LOG':
        return PostgreSQLSeverity.log;
      default:
        return PostgreSQLSeverity.unknown;
    }
  }

  final int? identificationToken;
  final String? text;

  ErrorField(this.identificationToken, this.text);
}
