import 'dart:collection';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import 'server_messages.dart';

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
  90: (d) => ReadyForQueryMessage(d),
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

      if (_hasReadHeader && _isComplete) {
        final data =
            _expectedLength == 0 ? _emptyData : _reader.read(_expectedLength);
        final msgMaker = _messageTypeMap[_type];
        final msg =
            msgMaker == null ? UnknownMessage(_type, data) : msgMaker(data);
        messageQueue.add(msg);
        _type = null;
        _expectedLength = 0;
        evaluateNextMessage = true;
      }
    }
  }

  bool get hasMessage => messageQueue.isNotEmpty;

  ServerMessage popMessage() {
    return messageQueue.removeFirst();
  }
}
