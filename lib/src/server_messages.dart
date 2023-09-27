import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:postgres/messages.dart';
import 'package:postgres/src/buffer.dart';

import 'connection.dart';
import 'query.dart';
import 'time_converters.dart';
import 'types.dart';

abstract class ServerMessage extends BaseMessage {}

sealed class ErrorOrNoticeMessage implements ServerMessage {
  final fields = <ErrorField>[];

  ErrorOrNoticeMessage._parse(PgByteDataReader reader, int length) {
    final targetRemainingLength = reader.remainingLength - length;
    while (reader.remainingLength > targetRemainingLength) {
      final identificationToken = reader.readUint8();
      if (identificationToken == 0) {
        break;
      }
      final message = reader.readNullTerminatedString();
      fields.add(ErrorField(identificationToken, message));
    }
  }
}

class ErrorResponseMessage extends ErrorOrNoticeMessage {
  @internal
  ErrorResponseMessage.parse(super.reader, super.length) : super._parse();
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
  static const int KindSASL = 10;
  static const int KindSASLContinue = 11;
  static const int KindSASLFinal = 12;

  final int type;
  late final Uint8List bytes;

  AuthenticationMessage._(this.type, this.bytes);

  @internal
  factory AuthenticationMessage.parse(PgByteDataReader reader, int length) {
    final type = reader.readUint32();
    return AuthenticationMessage._(type, reader.read(length - 4));
  }
}

class ParameterStatusMessage extends ServerMessage {
  final String name;
  final String value;

  ParameterStatusMessage._(this.name, this.value);

  @internal
  factory ParameterStatusMessage.parse(PgByteDataReader reader) {
    final name = reader.readNullTerminatedString();
    final value = reader.readNullTerminatedString();
    return ParameterStatusMessage._(name, value);
  }
}

class ReadyForQueryMessage extends ServerMessage {
  static const String StateIdle = 'I';
  static const String StateTransaction = 'T';
  static const String StateTransactionError = 'E';

  final String state;

  @internal
  ReadyForQueryMessage.parse(PgByteDataReader reader, int length)
      : state = reader.encoding.decode(reader.read(length));

  @override
  String toString() {
    return 'ReadyForQueryMessage(state = $state)';
  }
}

class BackendKeyMessage extends ServerMessage {
  final int processID;
  final int secretKey;

  BackendKeyMessage._(this.processID, this.secretKey);

  @internal
  factory BackendKeyMessage.parse(PgByteDataReader reader) {
    final processID = reader.readUint32();
    final secretKey = reader.readUint32();
    return BackendKeyMessage._(processID, secretKey);
  }
}

class RowDescriptionMessage extends ServerMessage {
  final fieldDescriptions = <FieldDescription>[];

  @internal
  RowDescriptionMessage.parse(PgByteDataReader reader) {
    final fieldCount = reader.readInt16();

    for (var i = 0; i < fieldCount; i++) {
      final rowDesc = FieldDescription.read(reader);
      fieldDescriptions.add(rowDesc);
    }
  }
}

class DataRowMessage extends ServerMessage {
  final values = <Uint8List?>[];

  @internal
  DataRowMessage.parse(PgByteDataReader reader) {
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

  @internal
  factory NotificationResponseMessage.parse(PgByteDataReader reader) {
    final processID = reader.readUint32();
    final channel = reader.readNullTerminatedString();
    final payload = reader.readNullTerminatedString();
    return NotificationResponseMessage._(processID, channel, payload);
  }
}

class CommandCompleteMessage extends ServerMessage {
  final int rowsAffected;

  /// Match the digits at the end of the string.
  /// Possible values are:
  ///  ```
  ///  command-tag | #rows
  ///  SELECT 1
  ///  UPDATE 1234
  ///  DELETE 568
  ///  MOVE 42
  ///  FETCH 60
  ///  COPY 314
  ///  ```
  ///  For INSERT, there are three columns:
  ///  ```
  ///  | command tag | oid* | #rows |
  ///  INSERT 0 42
  ///  ```
  ///  *oid is only used with `INSERT` and it's always 0.
  static final _affectedRowsExp = RegExp(r'\d+$');

  CommandCompleteMessage._(this.rowsAffected);

  @internal
  factory CommandCompleteMessage.parse(PgByteDataReader reader) {
    final str = reader.readNullTerminatedString();
    final match = _affectedRowsExp.firstMatch(str);
    var rowsAffected = 0;
    if (match != null) {
      rowsAffected = int.parse(match.group(0)!);
    }
    return CommandCompleteMessage._(rowsAffected);
  }

  @override
  String toString() {
    return 'CommandCompleteMessage($rowsAffected affected rows)';
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

class CloseCompleteMessage extends ServerMessage {
  CloseCompleteMessage();

  @override
  String toString() => 'Bind Complete Message';
}

class ParameterDescriptionMessage extends ServerMessage {
  final parameterTypeIDs = <int>[];

  @internal
  ParameterDescriptionMessage.parse(PgByteDataReader reader) {
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

class NoticeMessage extends ErrorOrNoticeMessage {
  @internal
  NoticeMessage.parse(super.reader, super.length) : super._parse();
}

/// Identifies the message as a Start Copy Both response.
/// This message is used only for Streaming Replication.
class CopyBothResponseMessage implements ServerMessage {
  /// 0 indicates the overall COPY format is textual (rows separated by newlines,
  /// columns separated by separator characters, etc). 1 indicates the overall copy
  /// format is binary (similar to DataRow format).
  late final int copyFormat;

  /// The format codes to be used for each column. Each must presently be zero (text)
  /// or one (binary). All must be zero if the overall copy format is textual
  final columnsFormatCode = <int>[];

  @internal
  CopyBothResponseMessage.parse(PgByteDataReader reader) {
    copyFormat = reader.readInt8();
    final numberOfColumns = reader.readInt16();
    for (var i = 0; i < numberOfColumns; i++) {
      columnsFormatCode.add(reader.readInt16());
    }
  }

  @override
  String toString() {
    final format = copyFormat == 0 ? 'textual' : 'binary';
    return 'CopyBothResponseMessage with $format COPY format for ${columnsFormatCode.length}-columns';
  }
}

class PrimaryKeepAliveMessage implements ReplicationMessage, ServerMessage {
  /// The current end of WAL on the server.
  late final LSN walEnd;
  late final DateTime time;
  // If `true`, it means that the client should reply to this message as soon as possible,
  // to avoid a timeout disconnect.
  late final bool mustReply;

  @internal
  PrimaryKeepAliveMessage.parse(PgByteDataReader reader) {
    walEnd = LSN(reader.readUint64());
    time = dateTimeFromMicrosecondsSinceY2k(reader.readUint64());
    mustReply = reader.readUint8() != 0;
  }

  @override
  String toString() =>
      'PrimaryKeepAliveMessage(walEnd: $walEnd, time: $time, mustReply: $mustReply)';
}

class XLogDataMessage implements ReplicationMessage, ServerMessage {
  final LSN walStart;
  final LSN walEnd;
  final DateTime time;
  final Uint8List bytes;
  // this is used for standby msg
  LSN get walDataLength => LSN(bytes.length);

  /// For physical replication, this is the raw [bytes]
  /// For logical replication, see [XLogDataLogicalMessage]
  Object get data => bytes;

  XLogDataMessage({
    required this.walStart,
    required this.walEnd,
    required this.time,
    required this.bytes,
  });

  /// Parses the XLogDataMessage
  ///
  /// If [XLogDataMessage.data] is a [LogicalReplicationMessage], then the method
  /// will return a [XLogDataLogicalMessage] with that message. Otherwise, it'll
  /// return [XLogDataMessage] with raw data.
  static XLogDataMessage parse(Uint8List bytes) {
    final reader = PgByteDataReader()..add(bytes);
    final walStart = LSN(reader.readUint64());
    final walEnd = LSN(reader.readUint64());
    final time = dateTimeFromMicrosecondsSinceY2k(reader.readUint64());

    final message =
        tryParseLogicalReplicationMessage(reader, reader.remainingLength);
    if (message != null) {
      return XLogDataLogicalMessage(
        message: message,
        bytes: bytes,
        time: time,
        walEnd: walEnd,
        walStart: walStart,
      );
    } else {
      return XLogDataMessage(
        bytes: bytes,
        time: time,
        walEnd: walEnd,
        walStart: walStart,
      );
    }
  }

  @override
  String toString() =>
      'XLogDataMessage(walStart: $walStart, walEnd: $walEnd, time: $time, data: $data)';
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
    if (other is! UnknownMessage) {
      return false;
    }
    if (bytes != null) {
      if (bytes!.length != other.bytes?.length) {
        return false;
      }
      for (var i = 0; i < bytes!.length; i++) {
        if (bytes![i] != other.bytes?[i]) {
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
