import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:postgres/src/types/type_codec.dart';

import '../buffer.dart';
import '../time_converters.dart';
import '../types.dart';
import 'logical_replication_messages.dart';
import 'shared_messages.dart';

abstract class ServerMessage extends Message {}

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

abstract class AuthenticationMessageType {
  static const int ok = 0;
  static const int kerberosV5 = 2;
  static const int clearTextPassword = 3;
  static const int md5Password = 5;
  static const int scmCredential = 6;
  static const int gss = 7;
  static const int gssContinue = 8;
  static const int sspi = 9;
  static const int sasl = 10;
  static const int saslContinue = 11;
  static const int saslFinal = 12;
}

class AuthenticationMessage implements ServerMessage {
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

abstract class ReadyForQueryMessageState {
  static const String idle = 'I';
  static const String transaction = 'T';
  static const String error = 'E';
}

class ReadyForQueryMessage extends ServerMessage {
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
  final int processId;
  final int secretKey;

  BackendKeyMessage._(this.processId, this.secretKey);

  @internal
  factory BackendKeyMessage.parse(PgByteDataReader reader) {
    final processId = reader.readUint32();
    final secretKey = reader.readUint32();
    return BackendKeyMessage._(processId, secretKey);
  }
}

class FieldDescription {
  final String fieldName;
  final int tableOid;
  final int columnOid;
  final int typeOid;
  final int typeSize;
  final int typeModifier;
  final int formatCode;

  FieldDescription._(
    this.fieldName,
    this.tableOid,
    this.columnOid,
    this.typeOid,
    this.typeSize,
    this.typeModifier,
    this.formatCode,
  );

  factory FieldDescription.read(PgByteDataReader reader) {
    final fieldName = reader.readNullTerminatedString();
    final tableOid = reader.readUint32();
    final columnOid = reader.readUint16();
    final typeOid = reader.readUint32();
    final dataTypeSize = reader.readUint16();
    final typeModifier = reader.readInt32();
    final formatCode = reader.readUint16();

    return FieldDescription._(
      fieldName,
      tableOid,
      columnOid,
      typeOid,
      dataTypeSize,
      typeModifier,
      formatCode,
    );
  }

  late final isBinaryEncoding = formatCode != 0;

  @override
  String toString() {
    return '$fieldName $tableOid $columnOid $typeOid $typeSize $typeModifier $formatCode';
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
  final int processId;
  final String channel;
  final String payload;

  NotificationResponseMessage._(this.processId, this.channel, this.payload);

  @internal
  factory NotificationResponseMessage.parse(PgByteDataReader reader) {
    final processId = reader.readUint32();
    final channel = reader.readNullTerminatedString();
    final payload = reader.readNullTerminatedString();
    return NotificationResponseMessage._(processId, channel, payload);
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
  final typeOids = <int>[];

  @internal
  ParameterDescriptionMessage.parse(PgByteDataReader reader) {
    final count = reader.readUint16();
    for (var i = 0; i < count; i++) {
      typeOids.add(reader.readUint32());
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
  ///
  @Deprecated(
      'It is likely that this method signature will change or will be removed in '
      'an upcoming release. Please file a new issue on GitHub if you are using it.')
  static XLogDataMessage parse(
    Uint8List bytes,
    Encoding encoding, {
    CodecContext? codecContext,
  }) {
    final reader = PgByteDataReader(
        codecContext:
            codecContext ?? CodecContext.withDefaults(encoding: encoding))
      ..add(bytes);
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
  final int code;
  final Uint8List bytes;

  UnknownMessage(this.code, this.bytes);

  @override
  int get hashCode {
    return bytes.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (other is! UnknownMessage) {
      return false;
    }
    if (code != other.code) return false;
    if (bytes.length != other.bytes.length) {
      return false;
    }
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] != other.bytes[i]) {
        return false;
      }
    }
    return true;
  }
}

abstract class ErrorFieldId {
  static const int severity = 83;
  static const int code = 67;
  static const int message = 77;
  static const int detail = 68;
  static const int hint = 72;
  static const int position = 80;
  static const int internalPosition = 112;
  static const int internalQuery = 113;
  static const int where = 87;
  static const int schema = 115;
  static const int table = 116;
  static const int column = 99;
  static const int dataType = 100;
  static const int constraint = 110;
  static const int file = 70;
  static const int line = 76;
  static const int routine = 82;
}

class ErrorField {
  final int id;
  final String text;

  ErrorField(this.id, this.text);
}
