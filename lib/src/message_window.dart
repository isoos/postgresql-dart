import 'dart:collection';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import 'logical_replication_messages.dart';
import 'server_messages.dart';
import 'shared_messages.dart';

const int _headerByteSize = 5;
final _emptyData = Uint8List(0);

typedef _ServerMessageFn = ServerMessage Function(Uint8List data);

Map<int, _ServerMessageFn> _messageTypeMap = {
  49: (d) => ParseCompleteMessage(),
  50: (d) => BindCompleteMessage(),
  65: (d) => NotificationResponseMessage(d),
  67: (d) => CommandCompleteMessage(d),
  68: (d) => DataRowMessage(d),
  69: (d) => ErrorResponseMessage(d),
  75: (d) => BackendKeyMessage(d),
  82: (d) => AuthenticationMessage(d),
  83: (d) => ParameterStatusMessage(d),
  84: (d) => RowDescriptionMessage(d),
  87: (d) => CopyBothResponseMessage(d),
  90: (d) => ReadyForQueryMessage(d),
  100: (d) => CopyDataMessage(d),
  110: (d) => NoDataMessage(),
  116: (d) => ParameterDescriptionMessage(d),
};

class MessageFramer {
  final _reader = ByteDataReader();
  final messageQueue = Queue<ServerMessage>();

  int? _type;
  int _expectedLength = 0;

  bool get _hasReadHeader => _type != null;
  bool get _canReadHeader => _reader.remainingLength >= _headerByteSize;

  bool get _isComplete =>
      _expectedLength == 0 || _expectedLength <= _reader.remainingLength;

  void addBytes(Uint8List bytes) {
    _reader.add(bytes);

    var evaluateNextMessage = true;
    while (evaluateNextMessage) {
      evaluateNextMessage = false;

      if (!_hasReadHeader && _canReadHeader) {
        _type = _reader.readUint8();
        _expectedLength = _reader.readUint32() - 4;
      }

      // special case
      if (_type == SharedMessages.copyDoneIdentifier) {
        // unlike other messages, CopyDoneMessage only takes the length as an
        // argument (must be the full length including the length bytes)
        final msg = CopyDoneMessage(_expectedLength + 4);
        _addMsg(msg);
        evaluateNextMessage = true;
      } else if (_hasReadHeader && _isComplete) {
        final data =
            _expectedLength == 0 ? _emptyData : _reader.read(_expectedLength);
        final msgMaker = _messageTypeMap[_type];
        var msg =
            msgMaker == null ? UnknownMessage(_type, data) : msgMaker(data);

        // Copy Data message is a wrapper around data stream messages
        // such as replication messages.
        if (msg is CopyDataMessage) {
          // check if it's a replication message, otherwise return raw CopyDataMessage
          msg = _extractReplicationMessageIfAny(msg);
        }

        _addMsg(msg);
        evaluateNextMessage = true;
      }
    }
  }

  void _addMsg(ServerMessage msg) {
    messageQueue.add(msg);
    _type = null;
    _expectedLength = 0;
  }

  /// Returns a [ReplicationMessage] if the [CopyDataMessage] contains such message.
  /// Otherwise, it'll just return the provided [copyData].
  ServerMessage _extractReplicationMessageIfAny(CopyDataMessage copyData) {
    final bytes = copyData.bytes;
    final code = bytes.first;
    final data = bytes.sublist(1);
    if (code == ReplicationMessage.primaryKeepAliveIdentifier) {
      return PrimaryKeepAliveMessage(data);
    } else if (code == ReplicationMessage.xLogDataIdentifier) {
      return tryParseLogicalReplicationMessage(XLogDataMessage(data));
    } else {
      return copyData;
    }
  }

  bool get hasMessage => messageQueue.isNotEmpty;

  ServerMessage popMessage() {
    return messageQueue.removeFirst();
  }
}
