import 'dart:convert';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:charcode/ascii.dart';

import 'constants.dart';
import 'encoded_string.dart';
import 'query.dart';
import 'replication.dart';
import 'shared_messages.dart';
import 'time_converters.dart';
import 'types.dart';
import 'v3/types.dart';

abstract class ClientMessage extends BaseMessage {
  static const int FormatText = 0;
  static const int FormatBinary = 1;

  static const int ProtocolVersion = 196608;

  static const int BindIdentifier = 66; // B
  static const int DescribeIdentifier = 68; // D
  static const int ExecuteIdentifier = 69; // E
  static const int ParseIdentifier = 80; //P
  static const int QueryIdentifier = 81; // Q
  static const int SyncIdentifier = 83; // S
  static const int PasswordIdentifier = 112; //p
  static const int CloseIdentifier = $C;

  const ClientMessage();

  void applyToBuffer(ByteDataWriter buffer);

  Uint8List asBytes() {
    final buffer = ByteDataWriter();
    applyToBuffer(buffer);
    return buffer.toBytes();
  }

  static Uint8List aggregateBytes(List<ClientMessage> messages) {
    final buffer = ByteDataWriter();
    for (final cm in messages) {
      cm.applyToBuffer(buffer);
    }
    return buffer.toBytes();
  }
}

class StartupMessage extends ClientMessage {
  final EncodedString? _username;
  final EncodedString _databaseName;
  final EncodedString _timeZone;
  final EncodedString _replication;

  StartupMessage(
    String databaseName,
    String timeZone, {
    String? username,
    ReplicationMode replication = ReplicationMode.none,
    required Encoding encoding,
  })  : _databaseName = EncodedString(databaseName, encoding),
        _timeZone = EncodedString(timeZone, encoding),
        _username =
            username == null ? null : EncodedString(username, encoding),
        _replication = EncodedString(replication.value, encoding);

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    var fixedLength = 48;
    var variableLength = _databaseName.byteLength + _timeZone.byteLength + 2;

    if (_username != null) {
      fixedLength += 5;
      variableLength += _username!.byteLength + 1;
    }

    if (_replication.string != ReplicationMode.none.value) {
      fixedLength += UTF8ByteConstants.replication.length;
      variableLength += _replication.byteLength + 1;
    }

    buffer.writeInt32(fixedLength + variableLength);
    buffer.writeInt32(ClientMessage.ProtocolVersion);

    if (_username != null) {
      buffer.write(UTF8ByteConstants.user);
      _username!.applyToBuffer(buffer);
    }

    if (_replication.string != ReplicationMode.none.value) {
      buffer.write(UTF8ByteConstants.replication);
      _replication.applyToBuffer(buffer);
    }

    buffer.write(UTF8ByteConstants.database);
    _databaseName.applyToBuffer(buffer);

    buffer.write(UTF8ByteConstants.clientEncoding);
    buffer.write(UTF8ByteConstants.utf8);

    buffer.write(UTF8ByteConstants.timeZone);
    _timeZone.applyToBuffer(buffer);

    buffer.writeInt8(0);
  }
}

class QueryMessage extends ClientMessage {
  final EncodedString _queryString;

  QueryMessage(String queryString, Encoding encoding)
      : _queryString = EncodedString(queryString, encoding);

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.QueryIdentifier);
    final length = 5 + _queryString.byteLength;
    buffer.writeUint32(length);
    _queryString.applyToBuffer(buffer);
  }
}

class ParseMessage extends ClientMessage {
  final EncodedString _statementName;
  final EncodedString _statement;
  final List<PgDataType?> _types;

  ParseMessage(
    String statement, {
    String statementName = '',
    List<PgDataType?>? types,
    required Encoding encoding,
  })  : _statement = EncodedString(statement, encoding),
        _statementName = EncodedString(statementName, encoding),
        _types = types ?? const [];

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.ParseIdentifier);
    final length = 8 +
        _statement.byteLength +
        _statementName.byteLength +
        _types.length * 4;
    buffer.writeUint32(length);
    // Name of prepared statement
    _statementName.applyToBuffer(buffer);
    _statement.applyToBuffer(buffer); // Query string

    // Parameters and their types
    buffer.writeUint16(_types.length);
    for (final type in _types) {
      buffer.writeInt32(type?.oid ?? 0);
    }
  }
}

class DescribeMessage extends ClientMessage {
  final EncodedString _name;
  final bool _isPortal;

  DescribeMessage({String statementName = '', required Encoding encoding})
      : _name = EncodedString(statementName, encoding),
        _isPortal = false;

  DescribeMessage.portal({String portalName = '', required Encoding encoding})
      : _name = EncodedString(portalName, encoding),
        _isPortal = true;

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.DescribeIdentifier);
    final length = 6 + _name.byteLength;
    buffer.writeUint32(length);
    buffer.writeUint8(_isPortal ? $P : $S);
    _name.applyToBuffer(buffer); // Name of prepared statement
  }
}

class BindMessage extends ClientMessage {
  final List<ParameterValue> _parameters;
  final EncodedString _portalName;
  final EncodedString _statementName;
  final int _typeSpecCount;
  int _cachedLength = -1;

  BindMessage(this._parameters,
      {String portalName = '',
      String statementName = '',
      required Encoding encoding})
      : _typeSpecCount = _parameters.where((p) => p.isBinary).length,
        _portalName = EncodedString(portalName, encoding),
        _statementName = EncodedString(statementName, encoding);

  int get length {
    if (_cachedLength == -1) {
      var inputParameterElementCount = _parameters.length;
      if (_typeSpecCount == _parameters.length || _typeSpecCount == 0) {
        inputParameterElementCount = 1;
      }

      _cachedLength = 15;
      _cachedLength += _statementName.byteLength;
      _cachedLength += _portalName.byteLength;
      _cachedLength += inputParameterElementCount * 2;
      _cachedLength +=
          _parameters.fold<int>(0, (len, ParameterValue paramValue) {
        if (paramValue.bytes == null) {
          return len + 4;
        } else {
          return len + 4 + paramValue.length;
        }
      });
    }
    return _cachedLength;
  }

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.BindIdentifier);
    buffer.writeUint32(length - 1);

    // Name of portal.
    _portalName.applyToBuffer(buffer);
    // Name of prepared statement.
    _statementName.applyToBuffer(buffer);

    // OK, if we have no specified types at all, we can use 0. If we have all specified types, we can use 1. If we have a mix, we have to individually
    // call out each type.
    if (_typeSpecCount == _parameters.length) {
      buffer.writeUint16(1);
      // Apply following format code for all parameters by indicating 1
      buffer.writeUint16(ClientMessage.FormatBinary);
    } else if (_typeSpecCount == 0) {
      buffer.writeUint16(1);
      // Apply following format code for all parameters by indicating 1
      buffer.writeUint16(ClientMessage.FormatText);
    } else {
      // Well, we have some text and some binary, so we have to be explicit about each one
      buffer.writeUint16(_parameters.length);
      for (final p in _parameters) {
        buffer.writeUint16(
            p.isBinary ? ClientMessage.FormatBinary : ClientMessage.FormatText);
      }
    }

    // This must be the number of $n's in the query.
    buffer.writeUint16(_parameters.length);
    for (final p in _parameters) {
      if (p.bytes == null) {
        buffer.writeInt32(-1);
      } else {
        buffer.writeInt32(p.length);
        buffer.write(p.bytes!);
      }
    }

    // Result columns - we always want binary for all of them, so specify 1:1.
    buffer.writeUint16(1);
    buffer.writeUint16(1);
  }
}

class ExecuteMessage extends ClientMessage {
  final EncodedString _portalName;

  ExecuteMessage(Encoding encoding, [String portalName = ''])
      : _portalName = EncodedString(portalName, encoding);

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.ExecuteIdentifier);
    buffer.writeUint32(9 + _portalName.byteLength);
    _portalName.applyToBuffer(buffer);
    buffer.writeUint32(0);
  }
}

class CloseMessage extends ClientMessage {
  final bool isForPortal;
  final EncodedString name;

  CloseMessage.statement(Encoding encoding, [String name = ''])
      : name = EncodedString(name, encoding),
        isForPortal = false;

  CloseMessage.portal(Encoding encoding, [String name = ''])
      : name = EncodedString(name, encoding),
        isForPortal = true;

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    final length = 6 + name.byteLength;

    buffer
      ..writeUint8(ClientMessage.CloseIdentifier)
      ..writeInt32(length)
      ..writeUint8(isForPortal ? $P : $S);
    name.applyToBuffer(buffer);
  }
}

class SyncMessage extends ClientMessage {
  const SyncMessage();

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.SyncIdentifier);
    buffer.writeUint32(4);
  }
}

class TerminateMessage extends ClientMessage {
  const TerminateMessage();

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer
      ..writeUint8($X)
      ..writeUint32(4);
  }
}

class StandbyStatusUpdateMessage extends ClientMessage
    implements ReplicationMessage {
  /// The WAL position that's been locally written
  final LSN walWritePosition;

  /// The WAL position that's been locally flushed
  late final LSN walFlushPosition;

  /// The WAL position that's been locally applied
  late final LSN walApplyPosition;

  /// Client system clock time
  late final DateTime clientTime;

  /// Request server to reply immediately.
  final bool mustReply;

  /// StandbyStatusUpdate to the PostgreSQL server.
  ///
  /// The only required field is [walWritePosition]. If either [walFlushPosition]
  /// or [walApplyPosition] are `null`, [walWritePosition] will be assigned to them.
  /// If [clientTime] is not given, then the current time is used.
  ///
  /// When sending this message, it must be wrapped within [CopyDataMessage]
  StandbyStatusUpdateMessage({
    required this.walWritePosition,
    LSN? walFlushPosition,
    LSN? walApplyPosition,
    DateTime? clientTime,
    this.mustReply = false,
  }) {
    this.walFlushPosition = walFlushPosition ?? walWritePosition;
    this.walApplyPosition = walApplyPosition ?? walWritePosition;
    this.clientTime = clientTime ?? DateTime.now().toUtc();
  }

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ReplicationMessage.standbyStatusUpdateIdentifier);
    buffer.writeUint64(walWritePosition.value);
    buffer.writeUint64(walFlushPosition.value);
    buffer.writeUint64(walApplyPosition.value);
    buffer.writeUint64(dateTimeToMicrosecondsSinceY2k(clientTime));
    buffer.writeUint8(mustReply ? 1 : 0);
  }
}

class HotStandbyFeedbackMessage extends ClientMessage
    implements ReplicationMessage {
  /// The client's system clock at the time of transmission, as microseconds since midnight on 2000-01-01.
  final DateTime clientTime;

  /// The standby's current global xmin, excluding the catalog_xmin from any
  /// replication slots. If both this value and the following catalog_xmin are 0
  /// this is treated as a notification that Hot Standby feedback will no longer
  /// be sent on this connection. Later non-zero messages may reinitiate the
  /// feedback mechanism
  final int currentGlobalXmin;

  /// The epoch of the global xmin xid on the standby.
  final int epochGlobalXminXid;

  /// The lowest catalog_xmin of any replication slots on the standby. Set to 0
  /// if no catalog_xmin exists on the standby or if hot standby feedback is
  /// being disabled.
  final int lowestCatalogXmin;

  /// The epoch of the catalog_xmin xid on the standby.
  final int epochCatalogXminXid;

  HotStandbyFeedbackMessage(
      this.clientTime,
      this.currentGlobalXmin,
      this.epochGlobalXminXid,
      this.lowestCatalogXmin,
      this.epochCatalogXminXid);

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ReplicationMessage.hotStandbyFeedbackIdentifier);
    buffer.writeUint64(dateTimeToMicrosecondsSinceY2k(clientTime));
    buffer.writeUint32(currentGlobalXmin);
    buffer.writeUint32(epochGlobalXminXid);
    buffer.writeUint32(lowestCatalogXmin);
    buffer.writeUint32(epochCatalogXminXid);
  }
}
