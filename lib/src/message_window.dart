import 'dart:collection';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import 'server_messages.dart';

class MessageFrame {
  static const int HeaderByteSize = 5;
  static Map<int, Function> messageTypeMap = {
    49: () => new ParseCompleteMessage(),
    50: () => new BindCompleteMessage(),
    65: () => new NotificationResponseMessage(),
    67: () => new CommandCompleteMessage(),
    68: () => new DataRowMessage(),
    69: () => new ErrorResponseMessage(),
    75: () => new BackendKeyMessage(),
    82: () => new AuthenticationMessage(),
    83: () => new ParameterStatusMessage(),
    84: () => new RowDescriptionMessage(),
    90: () => new ReadyForQueryMessage(),
    110: () => new NoDataMessage(),
    116: () => new ParameterDescriptionMessage()
  };

  bool get hasReadHeader => type != null;
  int type;
  int expectedLength;

  bool get isComplete => data != null || expectedLength == 0;
  Uint8List data;

  ServerMessage get message {
    var msgMaker =
        messageTypeMap[type] ?? () => new UnknownMessage()..code = type;

    ServerMessage msg = msgMaker();
    msg.readBytes(data);
    return msg;
  }
}

class MessageFramer {
  final _reader = new ByteDataReader();
  MessageFrame messageInProgress = new MessageFrame();
  final messageQueue = new Queue<MessageFrame>();

  void addBytes(Uint8List bytes) {
    _reader.add(bytes);

    bool evaluateNextMessage = true;
    while (evaluateNextMessage) {
      evaluateNextMessage = false;
      if (!messageInProgress.hasReadHeader &&
          _reader.remainingLength >= MessageFrame.HeaderByteSize) {
        messageInProgress.type = _reader.readUint8();
        messageInProgress.expectedLength = _reader.readUint32() - 4;
      }

      if (messageInProgress.hasReadHeader &&
          messageInProgress.expectedLength > 0 &&
          _reader.remainingLength >= messageInProgress.expectedLength) {
        messageInProgress.data = _reader.read(messageInProgress.expectedLength);
      }

      if (messageInProgress.isComplete) {
        messageQueue.add(messageInProgress);
        messageInProgress = new MessageFrame();
        evaluateNextMessage = true;
      }
    }
  }

  bool get hasMessage => messageQueue.isNotEmpty;

  MessageFrame popMessage() {
    return messageQueue.removeFirst();
  }
}
