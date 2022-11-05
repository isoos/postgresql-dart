import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:postgres/src/time_converters.dart';

import 'constants.dart';
import 'query.dart';
import 'replication.dart';

import 'shared_messages.dart';
import 'types.dart';
import 'utf8_backed_string.dart';

abstract class ClientMessage {
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
  final UTF8BackedString? _username;
  final UTF8BackedString _databaseName;
  final UTF8BackedString _timeZone;
  final UTF8BackedString _replication;

  StartupMessage(String databaseName, String timeZone,
      {String? username, ReplicationMode replication = ReplicationMode.none})
      : _databaseName = UTF8BackedString(databaseName),
        _timeZone = UTF8BackedString(timeZone),
        _username = username == null ? null : UTF8BackedString(username),
        _replication = UTF8BackedString(replication.value);

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    var fixedLength = 48;
    var variableLength = _databaseName.utf8Length + _timeZone.utf8Length + 2;

    if (_username != null) {
      fixedLength += 5;
      variableLength += _username!.utf8Length + 1;
    }

    if (_replication.string != ReplicationMode.none.value) {
      fixedLength += UTF8ByteConstants.replication.length;
      variableLength += _replication.utf8Length + 1;
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
  final UTF8BackedString _queryString;

  QueryMessage(String queryString)
      : _queryString = UTF8BackedString(queryString);

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.QueryIdentifier);
    final length = 5 + _queryString.utf8Length;
    buffer.writeUint32(length);
    _queryString.applyToBuffer(buffer);
  }
}

class ParseMessage extends ClientMessage {
  final UTF8BackedString _statementName;
  final UTF8BackedString _statement;

  ParseMessage(String statement, {String statementName = ''})
      : _statement = UTF8BackedString(statement),
        _statementName = UTF8BackedString(statementName);

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.ParseIdentifier);
    final length = 8 + _statement.utf8Length + _statementName.utf8Length;
    buffer.writeUint32(length);
    // Name of prepared statement
    _statementName.applyToBuffer(buffer);
    _statement.applyToBuffer(buffer); // Query string
    buffer.writeUint16(0);
  }
}

class DescribeMessage extends ClientMessage {
  final UTF8BackedString _statementName;

  DescribeMessage({String statementName = ''})
      : _statementName = UTF8BackedString(statementName);

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.DescribeIdentifier);
    final length = 6 + _statementName.utf8Length;
    buffer.writeUint32(length);
    buffer.writeUint8(83);
    _statementName.applyToBuffer(buffer); // Name of prepared statement
  }
}

class BindMessage extends ClientMessage {
  final List<ParameterValue> _parameters;
  final UTF8BackedString _statementName;
  final int _typeSpecCount;
  int _cachedLength = -1;

  BindMessage(this._parameters, {String statementName = ''})
      : _typeSpecCount = _parameters.where((p) => p.isBinary).length,
        _statementName = UTF8BackedString(statementName);

  int get length {
    if (_cachedLength == -1) {
      var inputParameterElementCount = _parameters.length;
      if (_typeSpecCount == _parameters.length || _typeSpecCount == 0) {
        inputParameterElementCount = 1;
      }

      _cachedLength = 15;
      _cachedLength += _statementName.utf8Length;
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

    // Name of portal - currently unnamed portal.
    buffer.writeUint8(0);
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
  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.ExecuteIdentifier);
    buffer.writeUint32(9);
    buffer.writeUint8(0); // Portal name
    buffer.writeUint32(0);
  }
}

class SyncMessage extends ClientMessage {
  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.SyncIdentifier);
    buffer.writeUint32(4);
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
