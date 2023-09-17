import 'dart:collection';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:charcode/ascii.dart';

import 'client_encoding.dart';
import 'server_messages.dart';
import 'shared_messages.dart';

const int _headerByteSize = 5;
final _emptyData = Uint8List(0);

typedef _ServerMessageFn = ServerMessage Function(
    Uint8List data, ClientEncoding clientEncoding);

Map<int, _ServerMessageFn> _messageTypeMap = {
  49: (d, e) => ParseCompleteMessage(),
  50: (d, e) => BindCompleteMessage(),
  65: NotificationResponseMessage.new,
  67: CommandCompleteMessage.new,
  68: DataRowMessage.new,
  69: (d, e) => ErrorResponseMessage(d),
  75: (d, e) => BackendKeyMessage(d),
  82: (d, e) => AuthenticationMessage(d),
  83: ParameterStatusMessage.new,
  84: (d, e) => RowDescriptionMessage(d),
  87: (d, e) => CopyBothResponseMessage(d),
  90: ReadyForQueryMessage.new,
  100: (d, e) => CopyDataMessage(d),
  110: (d, e) => NoDataMessage(),
  116: (d, e) => ParameterDescriptionMessage(d),
  $3: (d, e) => CloseCompleteMessage(),
  $N: (d, e) => NoticeMessage(d),
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

  void addBytes(Uint8List bytes, [ClientEncoding? clientEncoding]) {
    clientEncoding ??= ClientEncoding.utf8;
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
        var msg = msgMaker == null
            ? UnknownMessage(_type, data)
            : msgMaker(data, clientEncoding);

        // Copy Data message is a wrapper around data stream messages
        // such as replication messages.
        if (msg is CopyDataMessage) {
          // checks if it's a replication message, otherwise returns given msg
          msg = _extractReplicationMessageIfAny(msg, clientEncoding);
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
  ServerMessage _extractReplicationMessageIfAny(
      CopyDataMessage copyData, ClientEncoding clientEncoding) {
    final bytes = copyData.bytes;
    final code = bytes.first;
    final data = bytes.sublist(1);
    if (code == ReplicationMessage.primaryKeepAliveIdentifier) {
      return PrimaryKeepAliveMessage(data);
    } else if (code == ReplicationMessage.xLogDataIdentifier) {
      return XLogDataMessage.parse(data, clientEncoding);
    } else {
      return copyData;
    }
  }

  bool get hasMessage => messageQueue.isNotEmpty;

  ServerMessage popMessage() {
    return messageQueue.removeFirst();
  }
}
