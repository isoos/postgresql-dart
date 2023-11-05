import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:postgres/src/types/type_registry.dart';

import '../buffer.dart';
import '../time_converters.dart';
import '../types.dart';
import 'server_messages.dart';
import 'shared_messages.dart';

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
    PgByteDataReader reader, int length) {
  // the first byte is the msg type
  final firstByte = reader.readUint8();
  final msgType = LogicalReplicationMessageTypes.fromByte(firstByte);
  switch (msgType) {
    case LogicalReplicationMessageTypes.begin:
      return BeginMessage._parse(reader);

    case LogicalReplicationMessageTypes.commit:
      return CommitMessage._parse(reader);

    case LogicalReplicationMessageTypes.origin:
      return OriginMessage._parse(reader);

    case LogicalReplicationMessageTypes.relation:
      return RelationMessage._parse(reader);

    case LogicalReplicationMessageTypes.type:
      return TypeMessage._parse(reader);

    case LogicalReplicationMessageTypes.insert:
      return InsertMessage._parse(reader);

    case LogicalReplicationMessageTypes.update:
      return UpdateMessage._parse(reader);

    case LogicalReplicationMessageTypes.delete:
      return DeleteMessage._parse(reader);

    case LogicalReplicationMessageTypes.truncate:
      return TruncateMessage._parse(reader);

    case LogicalReplicationMessageTypes.unsupported:
      // wal2json messages starts with `{` as the first byte
      if (firstByte == '{'.codeUnits.single) {
        // note this needs the full set of bytes unlike other cases
        final bb = BytesBuffer();
        bb.addByte(firstByte);
        bb.add(reader.read(length - 1));
        try {
          return JsonMessage(reader.encoding.decode(bb.toBytes()));
        } catch (_) {
          // ignore
        }
      }
      return null;
  }
}

enum LogicalReplicationMessageTypes {
  begin('B'),
  commit('C'),
  origin('O'),
  relation('R'),
  type('Y'),
  insert('I'),
  update('U'),
  delete('D'),
  truncate('T'),
  unsupported('');

  final String id;
  const LogicalReplicationMessageTypes(this.id);

  static LogicalReplicationMessageTypes fromId(String id) {
    return LogicalReplicationMessageTypes.values.firstWhere(
      (element) => element.id == id,
      orElse: () => LogicalReplicationMessageTypes.unsupported,
    );
  }

  static LogicalReplicationMessageTypes fromByte(int byte) {
    return fromId(String.fromCharCode(byte));
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
  late final baseMessage = LogicalReplicationMessageTypes.begin;

  /// The final LSN of the transaction.
  late final LSN finalLSN;

  /// The commit timestamp of the transaction.
  late final DateTime commitTime;

  /// The transaction id
  late final int xid;

  BeginMessage._parse(PgByteDataReader reader) {
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
  late final baseMessage = LogicalReplicationMessageTypes.commit;

  // Flags currently unused (must be 0).
  late final int flags;

  /// The LSN of the commit.
  late final LSN commitLSN;

  /// The end LSN of the transaction.
  late final LSN transactionEndLSN;

  /// The commit timestamp of the transaction.
  late final DateTime commitTime;

  CommitMessage._parse(PgByteDataReader reader) {
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
  late final baseMessage = LogicalReplicationMessageTypes.origin;

  /// The LSN of the commit on the origin server.
  late final LSN commitLSN;

  late final String name;

  OriginMessage._parse(PgByteDataReader reader) {
    // reading order matters
    commitLSN = reader.readLSN();
    name = reader.readNullTerminatedString();
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
  final int typeOid;

  /// type modifier of the column (atttypmod).
  final int typeModifier;

  RelationMessageColumn({
    required this.flags,
    required this.name,
    required this.typeOid,
    required this.typeModifier,
  });

  @override
  String toString() {
    return 'RelationMessageColumn(flags: $flags, name: $name, typeOid: $typeOid, typeModifier: $typeModifier)';
  }
}

class RelationMessage implements LogicalReplicationMessage {
  /// The message type
  late final baseMessage = LogicalReplicationMessageTypes.relation;
  late final int relationId;
  late final String nameSpace;
  late final String relationName;
  late final int replicaIdentity;
  late final int columnNum;
  late final columns = <RelationMessageColumn>[];

  RelationMessage._parse(PgByteDataReader reader) {
    // reading order matters
    relationId = reader.readUint32();
    nameSpace = reader.readNullTerminatedString();
    relationName = reader.readNullTerminatedString();
    replicaIdentity = reader.readUint8();
    columnNum = reader.readUint16();

    for (var i = 0; i < columnNum; i++) {
      // reading order matters
      final flags = reader.readUint8();
      final name = reader.readNullTerminatedString();
      final typeOid = reader.readUint32();
      final typeModifier = reader.readUint32();
      columns.add(
        RelationMessageColumn(
          flags: flags,
          name: name,
          typeOid: typeOid,
          typeModifier: typeModifier,
        ),
      );
    }
  }

  @override
  String toString() {
    return 'RelationMessage(relationId: $relationId, nameSpace: $nameSpace, relationName: $relationName, replicaIdentity: $replicaIdentity, columnNum: $columnNum, columns: $columns)';
  }
}

class TypeMessage implements LogicalReplicationMessage {
  /// The message type
  late final baseMessage = LogicalReplicationMessageTypes.type;

  /// This is the type OID
  late final int typeOid;

  late final String nameSpace;

  late final String name;

  TypeMessage._parse(PgByteDataReader reader) {
    // reading order matters
    typeOid = reader.readUint32();
    nameSpace = reader.readNullTerminatedString();
    name = reader.readNullTerminatedString();
  }

  @override
  String toString() =>
      'TypeMessage(typeOid: $typeOid, nameSpace: $nameSpace, name: $name)';
}

enum TupleDataType {
  null_('n'),
  toast('u'),
  text('t'),
  binary('b');

  final String id;
  const TupleDataType(this.id);
  static TupleDataType fromId(String id) {
    return TupleDataType.values.firstWhere((element) => element.id == id);
  }

  static TupleDataType fromByte(int byte) {
    return fromId(String.fromCharCode(byte));
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
  final int typeId;
  final int length;

  String get typeName =>
      TypeRegistry.instance.tryResolveOid(typeId)?.name_ ?? typeId.toString();

  /// Data is the value of the column, in text format.
  /// n is the above length.
  final String data;

  TupleDataColumn({
    required this.typeId,
    required this.length,
    required this.data,
  });

  @override
  String toString() =>
      'TupleDataColumn(typeName: $typeName, length: $length, data: $data)';
}

class TupleData {
  /// The message type
  // late final ReplicationMessageTypes baseMessage;

  late final int columnCount;
  late final columns = <TupleDataColumn>[];

  /// TupleData does not consume the entire bytes
  ///
  /// It'll read until the types are generated.
  TupleData(PgByteDataReader reader) {
    columnCount = reader.readUint16();
    for (var i = 0; i < columnCount; i++) {
      // reading order matters
      final typeId = reader.readUint8();
      final tupleDataType = TupleDataType.fromByte(typeId);
      late final int length;
      late final String data;
      switch (tupleDataType) {
        case TupleDataType.text:
        case TupleDataType.binary:
          length = reader.readUint32();
          data = reader.encoding.decode(reader.read(length));
          break;
        case TupleDataType.null_:
        case TupleDataType.toast:
          length = 0;
          data = '';
          break;
      }
      columns.add(
        TupleDataColumn(
          typeId: typeId,
          length: length,
          data: data,
        ),
      );
    }
  }

  @override
  String toString() => 'TupleData(columnNum: $columnCount, columns: $columns)';
}

class InsertMessage implements LogicalReplicationMessage {
  /// The message type
  late final baseMessage = LogicalReplicationMessageTypes.insert;

  /// The ID of the relation corresponding to the ID in the relation message.
  late final int relationId;
  late final TupleData tuple;

  InsertMessage._parse(PgByteDataReader reader) {
    relationId = reader.readUint32();
    final tupleType = reader.readUint8();
    if (tupleType != 'N'.codeUnitAt(0)) {
      throw Exception("InsertMessage must have 'N' tuple type");
    }
    tuple = TupleData(reader);
  }

  @override
  String toString() => 'InsertMessage(relationId: $relationId, tuple: $tuple)';
}

enum UpdateMessageTuple {
  noneType('0'), // This is Zero not the letter 'O'
  keyType('K'),
  oldType('O'),
  newType('N');

  final String id;
  const UpdateMessageTuple(this.id);
  static UpdateMessageTuple fromId(String id) {
    return UpdateMessageTuple.values
        .firstWhere((element) => element.id == id, orElse: () => noneType);
  }

  static UpdateMessageTuple fromByte(int byte) {
    if (byte == 0) {
      return noneType;
    }
    return fromId(String.fromCharCode(byte));
  }
}

class UpdateMessage implements LogicalReplicationMessage {
  /// The message type
  late final baseMessage = LogicalReplicationMessageTypes.update;

  late final int relationId;

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

  UpdateMessage._parse(PgByteDataReader reader) {
    // reading order matters
    relationId = reader.readUint32();
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
    return 'UpdateMessage(relationId: $relationId, oldTupleType: $oldTupleType, oldTuple: $oldTuple, newTuple: $newTuple)';
  }
}

enum DeleteMessageTuple {
  keyType('K'),
  oldType('O'),
  unknown('');

  final String id;
  const DeleteMessageTuple(this.id);
  static DeleteMessageTuple fromId(String id) {
    return DeleteMessageTuple.values.firstWhere(
      (element) => element.id == id,
      orElse: () => unknown,
    );
  }

  static DeleteMessageTuple fromByte(int byte) {
    return fromId(String.fromCharCode(byte));
  }
}

class DeleteMessage implements LogicalReplicationMessage {
  /// The message type
  late final baseMessage = LogicalReplicationMessageTypes.delete;

  late final int relationId;

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

  DeleteMessage._parse(PgByteDataReader reader) {
    relationId = reader.readUint32();
    oldTupleType = DeleteMessageTuple.fromByte(reader.readUint8());

    switch (oldTupleType) {
      case DeleteMessageTuple.keyType:
      case DeleteMessageTuple.oldType:
        oldTuple = TupleData(reader);
        break;
      case DeleteMessageTuple.unknown:
        throw Exception('Unknown tuple type for DeleteMessage');
    }
  }

  @override
  String toString() =>
      'DeleteMessage(relationId: $relationId, oldTupleType: $oldTupleType, oldTuple: $oldTuple)';
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
  late final baseMessage = LogicalReplicationMessageTypes.truncate;

  late final int relationNum;

  late final TruncateOptions option;

  final relationIds = <int>[];

  TruncateMessage._parse(PgByteDataReader reader) {
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
}
