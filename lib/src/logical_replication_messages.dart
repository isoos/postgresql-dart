import 'dart:convert';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import 'server_messages.dart';
import 'shared_messages.dart';
import 'time_converters.dart';
import 'types.dart';

/// A base class for all [Logical Replication Message Formats][] from the server
///
/// [Logical Replication Message Formats]: https://www.postgresql.org/docs/current/protocol-logicalrep-message-formats.html
abstract class LogicalReplicationMessage
    implements ReplicationMessage, ServerMessage {}

class XLogDataLogicalMessage implements XLogDataMessage {
  @override
  final Uint8List bytes;

  @override
  final DateTime time;

  @override
  final LSN walEnd;

  @override
  final LSN walStart;

  @override
  LSN get walDataLength => LSN(bytes.length);

  late final LogicalReplicationMessage message;

  @override
  LogicalReplicationMessage get data => message;

  XLogDataLogicalMessage({
    required this.message,
    required this.bytes,
    required this.time,
    required this.walEnd,
    required this.walStart,
  });
}

/// Tries to check if the [bytesList] is a [LogicalReplicationMessage]. If so,
/// [LogicalReplicationMessage] is returned, otherwise `null` is returned.
LogicalReplicationMessage? tryParseLogicalReplicationMessage(
    Uint8List bytesList) {
  // the first byte is the msg type
  final firstByte = bytesList.first;
  final msgType = LogicalReplicationMessageTypes.fromByte(firstByte);
  // remaining bytes are the data
  final bytes = bytesList.sublist(1);
  switch (msgType) {
    case LogicalReplicationMessageTypes.Begin:
      return BeginMessage(bytes);

    case LogicalReplicationMessageTypes.Commit:
      return CommitMessage(bytes);

    case LogicalReplicationMessageTypes.Origin:
      return OriginMessage(bytes);

    case LogicalReplicationMessageTypes.Relation:
      return RelationMessage(bytes);

    case LogicalReplicationMessageTypes.Type:
      return TypeMessage(bytes);

    case LogicalReplicationMessageTypes.Insert:
      return InsertMessage(bytes);

    case LogicalReplicationMessageTypes.Update:
      return UpdateMessage(bytes);

    case LogicalReplicationMessageTypes.Delete:
      return DeleteMessage(bytes);

    case LogicalReplicationMessageTypes.Truncate:
      return TruncateMessage(bytes);

    case LogicalReplicationMessageTypes.Unsupported:
    default:
      // note this needs the full set of bytes unlike other cases
      return _tryParseJsonMessage(bytesList);
  }
}

LogicalReplicationMessage? _tryParseJsonMessage(Uint8List bytes) {
  // wal2json messages starts with `{` as the first byte
  if (bytes.first == '{'.codeUnits.first) {
    try {
      return JsonMessage(utf8.decode(bytes));
    } catch (e) {
      return null;
    }
  }
  return null;
}

enum LogicalReplicationMessageTypes {
  Begin('B'),
  Commit('C'),
  Origin('O'),
  Relation('R'),
  Type('Y'),
  Insert('I'),
  Update('U'),
  Delete('D'),
  Truncate('T'),
  Unsupported('');

  final String id;
  const LogicalReplicationMessageTypes(this.id);

  static LogicalReplicationMessageTypes fromID(String id) {
    return LogicalReplicationMessageTypes.values.firstWhere(
      (element) => element.id == id,
      orElse: () => LogicalReplicationMessageTypes.Unsupported,
    );
  }

  static LogicalReplicationMessageTypes fromByte(int byte) {
    return fromID(String.fromCharCode(byte));
  }
}

/// A non-standrd message for JSON data
///
/// This is mainly used to deliver wal2json messages which is a popular plugin
/// for decoding logical replication output.
class JsonMessage implements LogicalReplicationMessage {
  final String json;

  JsonMessage(this.json);

  @override
  String toString() => json;
}

/// A non-stnadard message for unkown messages
///
/// This message only holds the bytes as data.
class UnknownLogicalReplicationMessage implements LogicalReplicationMessage {
  final Uint8List bytes;

  UnknownLogicalReplicationMessage(this.bytes);

  @override
  String toString() => 'UnknownLogicalReplicationMessage(bytes: $bytes)';
}

class BeginMessage implements LogicalReplicationMessage {
  /// The message type
  late final baseMessage = LogicalReplicationMessageTypes.Begin;

  /// The final LSN of the transaction.
  late final LSN finalLSN;

  /// The commit timestamp of the transaction.
  late final DateTime commitTime;

  /// The transaction id
  late final int xid;

  BeginMessage(Uint8List bytes) {
    final reader = ByteDataReader()..add(bytes);
    // reading order matters
    finalLSN = reader.readLSN();
    commitTime = reader.readTime();
    xid = reader.readUint32();
  }

  @override
  String toString() =>
      'BeginMessage(finalLSN: $finalLSN, commitTime: $commitTime, xid: $xid)';
}

// CommitMessage is a commit message.
class CommitMessage implements LogicalReplicationMessage {
  /// The message type
  late final baseMessage = LogicalReplicationMessageTypes.Commit;

  // Flags currently unused (must be 0).
  late final int flags;

  /// The LSN of the commit.
  late final LSN commitLSN;

  /// The end LSN of the transaction.
  late final LSN transactionEndLSN;

  /// The commit timestamp of the transaction.
  late final DateTime commitTime;

  CommitMessage(Uint8List bytes) {
    final reader = ByteDataReader()..add(bytes);
    // reading order matters
    flags = reader.readUint8();
    commitLSN = reader.readLSN();
    transactionEndLSN = reader.readLSN();
    commitTime = reader.readTime();
  }

  @override
  String toString() {
    return 'CommitMessage(flags: $flags, commitLSN: $commitLSN, transactionEndLSN: $transactionEndLSN, commitTime: $commitTime)';
  }
}

class OriginMessage implements LogicalReplicationMessage {
  /// The message type
  late final baseMessage = LogicalReplicationMessageTypes.Origin;

  /// The LSN of the commit on the origin server.
  late final LSN commitLSN;

  late final String name;

  OriginMessage(Uint8List bytes) {
    final reader = ByteDataReader()..add(bytes);
    // reading order matters
    commitLSN = reader.readLSN();
    name = reader.decodeString();
  }

  @override
  String toString() => 'OriginMessage(commitLSN: $commitLSN, name: $name)';
}

class RelationMessageColumn {
  /// Flags for the column. Currently can be either 0 for no flags or 1 which
  /// marks the column as part of the key.
  final int flags;

  final String name;

  /// The ID of the column's data type.
  final int dataType;

  /// type modifier of the column (atttypmod).
  final int typeModifier;

  RelationMessageColumn({
    required this.flags,
    required this.name,
    required this.dataType,
    required this.typeModifier,
  });

  @override
  String toString() {
    return 'RelationMessageColumn(flags: $flags, name: $name, dataType: $dataType, typeModifier: $typeModifier)';
  }
}

class RelationMessage implements LogicalReplicationMessage {
  /// The message type
  late final baseMessage = LogicalReplicationMessageTypes.Relation;
  late final int relationID;
  late final String nameSpace;
  late final String relationName;
  late final int replicaIdentity;
  late final int columnNum;
  late final columns = <RelationMessageColumn>[];

  RelationMessage(Uint8List bytes) {
    final reader = ByteDataReader()..add(bytes);
    // reading order matters
    relationID = reader.readUint32();
    nameSpace = reader.decodeString();
    relationName = reader.decodeString();
    replicaIdentity = reader.readUint8();
    columnNum = reader.readUint16();

    for (var i = 0; i < columnNum; i++) {
      // reading order matters
      final flags = reader.readUint8();
      final name = reader.decodeString();
      final dataType = reader.readUint32();
      final typeModifier = reader.readUint32();
      columns.add(
        RelationMessageColumn(
          flags: flags,
          name: name,
          dataType: dataType,
          typeModifier: typeModifier,
        ),
      );
    }
  }

  @override
  String toString() {
    return 'RelationMessage(relationID: $relationID, nameSpace: $nameSpace, relationName: $relationName, replicaIdentity: $replicaIdentity, columnNum: $columnNum, columns: $columns)';
  }
}

class TypeMessage implements LogicalReplicationMessage {
  /// The message type
  late final baseMessage = LogicalReplicationMessageTypes.Type;

  /// This is the type OID
  // TODO: create a getter for the type as a string
  late final int dataType;

  late final String nameSpace;

  late final String name;

  TypeMessage(Uint8List bytes) {
    final reader = ByteDataReader()..add(bytes);
    // reading order matters
    dataType = reader.readUint32();
    nameSpace = reader.decodeString();
    name = reader.decodeString();
  }

  @override
  String toString() =>
      'TypeMessage(dataType: $dataType, nameSpace: $nameSpace, name: $name)';
}

enum TupleDataType {
  nullType('n'),
  toastType('u'),
  textType('t'),
  binaryType('b');

  final String id;
  const TupleDataType(this.id);
  static TupleDataType fromID(String id) {
    return TupleDataType.values.firstWhere((element) => element.id == id);
  }

  static TupleDataType fromByte(int byte) {
    return fromID(String.fromCharCode(byte));
  }
}

class TupleDataColumn {
  /// Indicates the how does the data is stored.
  ///	 Byte1('n') Identifies the data as NULL value.
  ///	 Or
  ///	 Byte1('u') Identifies unchanged TOASTed value (the actual value is not sent).
  ///	 Or
  ///	 Byte1('t') Identifies the data as text formatted value.
  ///	 Or
  ///	 Byte1('b') Identifies the data as binary value.
  final int dataType;
  final int length;

  String get dataTypeName =>
      PostgreSQLDataType.byTypeOid[dataType]?.name ?? dataType.toString();

  /// Data is the value of the column, in text format.
  /// n is the above length.
  final String data;

  TupleDataColumn({
    required this.dataType,
    required this.length,
    required this.data,
  });

  @override
  String toString() =>
      'TupleDataColumn(dataType: $dataTypeName, length: $length, data: $data)';
}

class TupleData {
  /// The message type
  // late final ReplicationMessageTypes baseMessage;

  late final int columnNum;
  late final columns = <TupleDataColumn>[];

  /// TupleData does not consume the entire bytes
  ///
  /// It'll read until the types are generated.
  TupleData(ByteDataReader reader) {
    columnNum = reader.readUint16();
    for (var i = 0; i < columnNum; i++) {
      // reading order matters
      final dataType = reader.readUint8();
      final tupleDataType = TupleDataType.fromByte(dataType);
      late final int length;
      late final Uint8List data;
      switch (tupleDataType) {
        case TupleDataType.textType:
        case TupleDataType.binaryType:
          length = reader.readUint32();
          data = reader.read(length);
          break;
        case TupleDataType.nullType:
        case TupleDataType.toastType:
          length = 0;
          data = Uint8List(0);
          break;
      }
      columns.add(
        TupleDataColumn(
          dataType: dataType,
          length: length,
          data: utf8.decode(data),
        ),
      );
    }
  }

  @override
  String toString() => 'TupleData(columnNum: $columnNum, columns: $columns)';
}

class InsertMessage implements LogicalReplicationMessage {
  /// The message type
  late final baseMessage = LogicalReplicationMessageTypes.Insert;

  /// The ID of the relation corresponding to the ID in the relation message.
  late final int relationID;
  late final TupleData tuple;

  InsertMessage(Uint8List bytes) {
    final reader = ByteDataReader()..add(bytes);
    relationID = reader.readUint32();
    final tupleType = reader.readUint8();
    if (tupleType != 'N'.codeUnitAt(0)) {
      throw Exception("InsertMessage must have 'N' tuple type");
    }
    tuple = TupleData(reader);
  }

  @override
  String toString() => 'InsertMessage(relationID: $relationID, tuple: $tuple)';
}

enum UpdateMessageTuple {
  noneType('0'), // This is Zero not the letter 'O'
  keyType('K'),
  oldType('O'),
  newType('N');

  final String id;
  const UpdateMessageTuple(this.id);
  static UpdateMessageTuple fromID(String id) {
    return UpdateMessageTuple.values
        .firstWhere((element) => element.id == id, orElse: () => noneType);
  }

  static UpdateMessageTuple fromByte(int byte) {
    if (byte == 0) {
      return noneType;
    }
    return fromID(String.fromCharCode(byte));
  }
}

class UpdateMessage implements LogicalReplicationMessage {
  /// The message type
  late final baseMessage = LogicalReplicationMessageTypes.Update;

  late final int relationID;

  /// OldTupleType
  ///   Byte1('K'):
  ///     Identifies the following TupleData submessage as a key.
  ///     This field is optional and is only present if the update changed data
  ///     in any of the column(s) that are part of the REPLICA IDENTITY index.
  ///
  ///   Byte1('O'):
  ///     Identifies the following TupleData submessage as an old tuple.
  ///     This field is optional & is only present if table in which the update
  ///     happened has REPLICA IDENTITY set to FULL.
  ///
  /// The Update message may contain either a 'K' message part or an 'O' message
  /// part or neither of them, but never both of them.
  late final UpdateMessageTuple? oldTupleType;
  late final TupleData? oldTuple;

  /// NewTuple is the contents of a new tuple.
  ///   Byte1('N'): Identifies the following TupleData message as a new tuple.
  late final TupleData? newTuple;

  UpdateMessage(Uint8List bytes) {
    final reader = ByteDataReader()..add(bytes);
    // reading order matters
    relationID = reader.readUint32();
    var tupleType = UpdateMessageTuple.fromByte(reader.readUint8());

    if (tupleType == UpdateMessageTuple.oldType ||
        tupleType == UpdateMessageTuple.keyType) {
      oldTupleType = tupleType;
      oldTuple = TupleData(reader);
      tupleType = UpdateMessageTuple.fromByte(reader.readUint8());
    } else {
      oldTupleType = null;
      oldTuple = null;
    }

    if (tupleType == UpdateMessageTuple.newType) {
      newTuple = TupleData(reader);
    } else {
      throw Exception('Invalid Tuple Type for UpdateMessage');
    }
  }

  @override
  String toString() {
    return 'UpdateMessage(relationID: $relationID, oldTupleType: $oldTupleType, oldTuple: $oldTuple, newTuple: $newTuple)';
  }
}

enum DeleteMessageTuple {
  keyType('K'),
  oldType('O'),
  unknown('');

  final String id;
  const DeleteMessageTuple(this.id);
  static DeleteMessageTuple fromID(String id) {
    return DeleteMessageTuple.values.firstWhere(
      (element) => element.id == id,
      orElse: () => unknown,
    );
  }

  static DeleteMessageTuple fromByte(int byte) {
    return fromID(String.fromCharCode(byte));
  }
}

class DeleteMessage implements LogicalReplicationMessage {
  /// The message type
  late final baseMessage = LogicalReplicationMessageTypes.Delete;

  late final int relationID;

  /// OldTupleType
  ///   Byte1('K'):
  ///     Identifies the following TupleData submessage as a key.
  ///     This field is optional and is only present if the update changed data
  ///     in any of the column(s) that are part of the REPLICA IDENTITY index.
  ///
  ///   Byte1('O'):
  ///     Identifies the following TupleData submessage as an old tuple.
  ///     This field is optional & is only present if table in which the update
  ///     happened has REPLICA IDENTITY set to FULL.
  ///
  /// The Update message may contain either a 'K' message part or an 'O' message
  /// part or neither of them, but never both of them.
  late final DeleteMessageTuple oldTupleType;

  /// NewTuple is the contents of a new tuple.
  ///   Byte1('N'): Identifies the following TupleData message as a new tuple.
  late final TupleData oldTuple;

  DeleteMessage(Uint8List bytes) {
    final reader = ByteDataReader()..add(bytes);
    relationID = reader.readUint32();
    oldTupleType = DeleteMessageTuple.fromByte(reader.readUint8());

    switch (oldTupleType) {
      case DeleteMessageTuple.keyType:
      case DeleteMessageTuple.oldType:
        oldTuple = TupleData(reader);
        break;
      default:
        throw Exception('Unknown tuple type for DeleteMessage');
    }
  }

  @override
  String toString() =>
      'DeleteMessage(relationID: $relationID, oldTupleType: $oldTupleType, oldTuple: $oldTuple)';
}

// see https://www.postgresql.org/docs/current/protocol-logicalrep-message-formats.html
enum TruncateOptions {
  cascade(1),
  restartIdentity(2),
  none(0);

  final int value;
  const TruncateOptions(this.value);

  static TruncateOptions fromValue(int value) {
    return TruncateOptions.values
        .firstWhere((element) => element.value == value, orElse: () => none);
  }
}

class TruncateMessage implements LogicalReplicationMessage {
  /// The message type
  late final baseMessage = LogicalReplicationMessageTypes.Truncate;

  late final int relationNum;

  late final TruncateOptions option;

  final relationIds = <int>[];

  TruncateMessage(Uint8List bytes) {
    final reader = ByteDataReader()..add(bytes);
    relationNum = reader.readUint32();
    option = TruncateOptions.fromValue(reader.readUint8());
    for (var i = 0; i < relationNum; i++) {
      final id = reader.readUint32();
      relationIds.add(id);
    }
  }

  @override
  String toString() =>
      'TruncateMessage(relationNum: $relationNum, option: $option, relationIds: $relationIds)';
}

/// Extension contain commonly used methods within this file
extension on ByteDataReader {
  LSN readLSN() {
    return LSN(readUint64());
  }

  DateTime readTime() {
    return dateTimeFromMicrosecondsSinceY2k(readUint64());
  }

  /// Decodes a string from reader current offset
  ///
  /// String type definition: https://www.postgresql.org/docs/current/protocol-message-types.html
  /// String(s)
  ///   A null-terminated string (C-style string). There is no specific length limitation on strings.
  ///   If s is specified it is the exact value that will appear, otherwise the value is variable.
  ///   Eg. String, String("user").
  ///
  /// If there is no null byte, return empty string.
  String decodeString() {
    var foundNullByte = false;
    final string = <int>[];
    while (remainingLength > 0) {
      final byte = readUint8();
      if (byte == 0) {
        foundNullByte = true;
        break;
      }
      string.add(byte);
    }

    if (!foundNullByte) {
      return '';
    }

    return utf8.decode(string);
  }
}
