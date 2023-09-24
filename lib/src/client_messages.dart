import 'dart:typed_data';

import 'package:charcode/ascii.dart';
import 'package:postgres/src/time_converters.dart';
import 'package:postgres/src/v3/types.dart';

import 'buffer.dart';
import 'constants.dart';
import 'query.dart';
import 'replication.dart';

import 'shared_messages.dart';
import 'types.dart';

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

  void applyToBuffer(PgByteDataWriter buffer);

  Uint8List asBytes() {
    final buffer = PgByteDataWriter();
    applyToBuffer(buffer);
    return buffer.toBytes();
  }

  static Uint8List aggregateBytes(List<ClientMessage> messages) {
    final buffer = PgByteDataWriter();
    for (final cm in messages) {
      cm.applyToBuffer(buffer);
    }
    return buffer.toBytes();
  }
}

class StartupMessage extends ClientMessage {
  final String? _username;
  final String _databaseName;
  final String _timeZone;
  final String _replication;

  StartupMessage(
    String databaseName,
    String timeZone, {
    String? username,
    ReplicationMode replication = ReplicationMode.none,
  })  : _databaseName = databaseName,
        _timeZone = timeZone,
        _username = username,
        _replication = replication.value;

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    final databaseName = buffer.prepareString(_databaseName);
    final timeZone = buffer.prepareString(_timeZone);
    final username =
        _username == null ? null : buffer.prepareString(_username!);
    final replication = buffer.prepareString(_replication);
    var fixedLength = 44 + buffer.encodingName.bytesLength;
    var variableLength = databaseName.bytesLength + timeZone.bytesLength + 2;

    if (username != null) {
      fixedLength += 5;
      variableLength += username.bytesLength + 1;
    }

    if (_replication != ReplicationMode.none.value) {
      fixedLength += UTF8ByteConstants.replication.length;
      variableLength += replication.bytesLength + 1;
    }

    buffer.writeInt32(fixedLength + variableLength);
    buffer.writeInt32(ClientMessage.ProtocolVersion);

    if (username != null) {
      buffer.write(UTF8ByteConstants.user);
      buffer.writeEncodedString(username);
    }

    if (_replication != ReplicationMode.none.value) {
      buffer.write(UTF8ByteConstants.replication);
      buffer.writeEncodedString(replication);
    }

    buffer.write(UTF8ByteConstants.database);
    buffer.writeEncodedString(databaseName);

    buffer.write(UTF8ByteConstants.clientEncoding);
    buffer.writeEncodedString(buffer.encodingName);

    buffer.write(UTF8ByteConstants.timeZone);
    buffer.writeEncodedString(timeZone);

    buffer.writeInt8(0);
  }
}

class QueryMessage extends ClientMessage {
  final String _queryString;

  QueryMessage(this._queryString);

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.QueryIdentifier);
    buffer.writeLengthEncodedString(_queryString);
  }
}

class ParseMessage extends ClientMessage {
  final String _statementName;
  final String _statement;
  final List<PgDataType?> _types;

  ParseMessage(String statement,
      {String statementName = '', List<PgDataType?>? types})
      : _statement = statement,
        _statementName = statementName,
        _types = types ?? const [];

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.ParseIdentifier);
    final statement = buffer.prepareString(_statement);
    final statementName = buffer.prepareString(_statementName);
    final length = 8 +
        statement.bytesLength +
        statementName.bytesLength +
        _types.length * 4;
    buffer.writeUint32(length);
    // Name of prepared statement
    buffer.writeEncodedString(statementName);
    buffer.writeEncodedString(statement); // Query string

    // Parameters and their types
    buffer.writeUint16(_types.length);
    for (final type in _types) {
      buffer.writeInt32(type?.oid ?? 0);
    }
  }
}

class DescribeMessage extends ClientMessage {
  final String _name;
  final bool _isPortal;

  DescribeMessage({String statementName = ''})
      : _name = statementName,
        _isPortal = false;

  DescribeMessage.portal({String portalName = ''})
      : _name = portalName,
        _isPortal = true;

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.DescribeIdentifier);
    final name = buffer.prepareString(_name);
    final length = 6 + name.bytesLength;
    buffer.writeUint32(length);
    buffer.writeUint8(_isPortal ? $P : $S);
    buffer.writeEncodedString(name); // Name of prepared statement
  }
}

class BindMessage extends ClientMessage {
  final List<ParameterValue> _parameters;
  final String _portalName;
  final String _statementName;

  BindMessage(this._parameters,
      {String portalName = '', String statementName = ''})
      : _portalName = portalName,
        _statementName = statementName;

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.BindIdentifier);
    final portalName = buffer.prepareString(_portalName);
    final statementName = buffer.prepareString(_statementName);

    final parameterBytes = _parameters.map((p) => p.encodeAsBytes()).toList();
    final typeSpecCount = _parameters.where((p) => p.hasKnownType).length;
    var inputParameterElementCount = _parameters.length;
    if (typeSpecCount == _parameters.length || typeSpecCount == 0) {
      inputParameterElementCount = 1;
    }

    var length = 14;
    length += statementName.bytesLength;
    length += portalName.bytesLength;
    length += inputParameterElementCount * 2;
    length += parameterBytes.fold<int>(
        0, (len, bytes) => len + 4 + (bytes?.length ?? 0));

    buffer.writeUint32(length);

    // Name of portal.
    buffer.writeEncodedString(portalName);
    // Name of prepared statement.
    buffer.writeEncodedString(statementName);

    // OK, if we have no specified types at all, we can use 0. If we have all specified types, we can use 1. If we have a mix, we have to individually
    // call out each type.
    if (typeSpecCount == _parameters.length) {
      buffer.writeUint16(1);
      // Apply following format code for all parameters by indicating 1
      buffer.writeUint16(ClientMessage.FormatBinary);
    } else if (typeSpecCount == 0) {
      buffer.writeUint16(1);
      // Apply following format code for all parameters by indicating 1
      buffer.writeUint16(ClientMessage.FormatText);
    } else {
      // Well, we have some text and some binary, so we have to be explicit about each one
      buffer.writeUint16(_parameters.length);
      for (final p in _parameters) {
        buffer.writeUint16(p.hasKnownType
            ? ClientMessage.FormatBinary
            : ClientMessage.FormatText);
      }
    }

    // This must be the number of $n's in the query.
    buffer.writeUint16(_parameters.length);
    for (final bytes in parameterBytes) {
      if (bytes == null) {
        buffer.writeInt32(-1);
      } else {
        buffer.writeInt32(bytes.length);
        buffer.write(bytes);
      }
    }

    // Result columns - we always want binary for all of them, so specify 1:1.
    buffer.writeUint16(1);
    buffer.writeUint16(1);
  }
}

class ExecuteMessage extends ClientMessage {
  final String _portalName;

  ExecuteMessage([String portalName = '']) : _portalName = portalName;

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.ExecuteIdentifier);
    final portalName = buffer.prepareString(_portalName);
    buffer.writeUint32(9 + portalName.bytesLength);
    buffer.writeEncodedString(portalName);
    buffer.writeUint32(0);
  }
}

class CloseMessage extends ClientMessage {
  final bool _isForPortal;
  final String _name;

  CloseMessage.statement([String name = ''])
      : _name = name,
        _isForPortal = false;

  CloseMessage.portal([String name = ''])
      : _name = name,
        _isForPortal = true;

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    final name = buffer.prepareString(_name);
    final length = 6 + name.bytesLength;

    buffer
      ..writeUint8(ClientMessage.CloseIdentifier)
      ..writeInt32(length)
      ..writeUint8(_isForPortal ? $P : $S);
    buffer.writeEncodedString(name);
  }
}

class SyncMessage extends ClientMessage {
  const SyncMessage();

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.SyncIdentifier);
    buffer.writeUint32(4);
  }
}

class TerminateMessage extends ClientMessage {
  const TerminateMessage();

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
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
  void applyToBuffer(PgByteDataWriter buffer) {
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
  void applyToBuffer(PgByteDataWriter buffer) {
    buffer.writeUint8(ReplicationMessage.hotStandbyFeedbackIdentifier);
    buffer.writeUint64(dateTimeToMicrosecondsSinceY2k(clientTime));
    buffer.writeUint32(currentGlobalXmin);
    buffer.writeUint32(epochGlobalXminXid);
    buffer.writeUint32(lowestCatalogXmin);
    buffer.writeUint32(epochCatalogXminXid);
  }
}
