import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:charcode/ascii.dart';
import 'package:postgres/src/timezone_settings.dart';

import 'buffer.dart';
import 'messages/server_messages.dart';
import 'messages/shared_messages.dart';

const int _headerByteSize = 5;

typedef _ServerMessageFn = ServerMessage Function(
    PgByteDataReader reader, int length);

// Map<int, _ServerMessageFn> _messageTypeMap = {
//   49: (_, __) => ParseCompleteMessage(),
//   50: (_, __) => BindCompleteMessage(),
//   65: (r, _) => NotificationResponseMessage.parse(r),
//   67: (r, _) => CommandCompleteMessage.parse(r),
//   68: (r, _) => DataRowMessage.parse(r),
//   69: ErrorResponseMessage.parse,
//   75: (r, _) => BackendKeyMessage.parse(r),
//   82: AuthenticationMessage.parse,
//   83: (r, l) => ParameterStatusMessage.parse(r),
//   84: (r, _) => RowDescriptionMessage.parse(r),
//   87: (r, _) => CopyBothResponseMessage.parse(r),
//   90: ReadyForQueryMessage.parse,
//   100: _parseCopyDataMessage,
//   110: (_, __) => NoDataMessage(),
//   116: (r, _) => ParameterDescriptionMessage.parse(r),
//   $3: (_, __) => CloseCompleteMessage(),
//   $N: NoticeMessage.parse,
// };

class MessageFramer {
  final Encoding _encoding;
  TimeZoneSettings timeZone;
  late final _reader = PgByteDataReader(encoding: _encoding, timeZone: timeZone);
  final messageQueue = Queue<ServerMessage>();

  MessageFramer(this._encoding, this.timeZone);

  _ServerMessageFn? _messageTypeMap(int? messageType) {
    switch (messageType) {
      case 49:
        return (_, __) => ParseCompleteMessage();
      case 50:
        return (_, __) => BindCompleteMessage();
      case 65:
        return (r, _) => NotificationResponseMessage.parse(r);
      case 67:
        return (r, _) => CommandCompleteMessage.parse(r);
      case 68:
        return (r, _) => DataRowMessage.parse(r);
      case 69:
        return ErrorResponseMessage.parse;
      case 75:
        return (r, _) => BackendKeyMessage.parse(r);
      case 82:
        return AuthenticationMessage.parse;
      case 83:
        return (r, l) => ParameterStatusMessage.parse(r);
      case 84:
        return (r, _) => RowDescriptionMessage.parse(r);
      case 87:
        return (r, _) => CopyBothResponseMessage.parse(r);
      case 90:
        return ReadyForQueryMessage.parse;
      case 100:
        return _parseCopyDataMessage;
      case 110:
        return (_, __) => NoDataMessage();
      case 116:
        return (r, _) => ParameterDescriptionMessage.parse(r);
      case $3:
        return (_, __) => CloseCompleteMessage();
      case $N:
        return NoticeMessage.parse;
    }
    return null;
  }

  int? _type;
  int _expectedLength = 0;

  bool get _hasReadHeader => _type != null;
  bool get _canReadHeader => _reader.remainingLength >= _headerByteSize;

  bool get _isComplete =>
      _expectedLength == 0 || _expectedLength <= _reader.remainingLength;

  void addBytes(Uint8List bytes) {
    _reader.add(bytes);

    while (true) {
      if (!_hasReadHeader && _canReadHeader) {
        _type = _reader.readUint8();
        _expectedLength = _reader.readUint32() - 4;
      }

      // special case
      if (_type == SharedMessageId.copyDone) {
        // unlike other messages, CopyDoneMessage only takes the length as an
        // argument (must be the full length including the length bytes)
        final msg = CopyDoneMessage(_expectedLength + 4);
        _addMsg(msg);
        continue;
      }

      if (_hasReadHeader && _isComplete) {
        final msgMaker = _messageTypeMap(_type);
        if (msgMaker == null) {
          _addMsg(UnknownMessage(_type!, _reader.read(_expectedLength)));
          continue;
        }

        final targetRemainingLength = _reader.remainingLength - _expectedLength;
        final msg = msgMaker(_reader, _expectedLength);
        if (_reader.remainingLength > targetRemainingLength) {
          throw StateError(
              'Message parser consumed more bytes than expected. type=$_type expectedLength=$_expectedLength');
        }
        // consume the rest of the message
        if (_reader.remainingLength < targetRemainingLength) {
          _reader.read(targetRemainingLength - _reader.remainingLength);
        }

        _addMsg(msg);
        continue;
      }

      break;
    }
  }

  void _addMsg(ServerMessage msg) {
    messageQueue.add(msg);
    _type = null;
    _expectedLength = 0;
  }

  bool get hasMessage => messageQueue.isNotEmpty;

  ServerMessage popMessage() {
    return messageQueue.removeFirst();
  }
}

/// Copy Data message is a wrapper around data stream messages
/// such as replication messages.
/// Returns a [ReplicationMessage] if the message contains such message.
/// Otherwise, it'll just return the provided bytes as [CopyDataMessage].
ServerMessage _parseCopyDataMessage(PgByteDataReader reader, int length) {
  final code = reader.readUint8();
  if (code == ReplicationMessageId.primaryKeepAlive) {
    return PrimaryKeepAliveMessage.parse(reader);
  } else if (code == ReplicationMessageId.xLogData) {
    return XLogDataMessage.parse(reader.read(length - 1), reader.encoding, reader.timeZone);
  } else {
    final bb = BytesBuffer();
    bb.addByte(code);
    bb.add(reader.read(length - 1));
    return CopyDataMessage(bb.toBytes());
  }
}
