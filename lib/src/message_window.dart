import 'dart:collection';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import 'server_messages.dart';

class MessageFrame {
  static const int HeaderByteSize = 5;
  static Map<int, Function> messageTypeMap = {
    49: () => ParseCompleteMessage(),
    50: () => BindCompleteMessage(),
    65: () => NotificationResponseMessage(),
    67: () => CommandCompleteMessage(),
    68: () => DataRowMessage(),
    69: () => ErrorResponseMessage(),
    75: () => BackendKeyMessage(),
    82: () => AuthenticationMessage(),
    83: () => ParameterStatusMessage(),
    84: () => RowDescriptionMessage(),
    90: () => ReadyForQueryMessage(),
    110: () => NoDataMessage(),
    116: () => ParameterDescriptionMessage()
  };

  bool get hasReadHeader => type != null;
  int type;
  int expectedLength;

  bool get isComplete => data != null || expectedLength == 0;
  Uint8List data;

  ServerMessage get message {
    final msgMaker =
        messageTypeMap[type] ?? () => UnknownMessage()..code = type;

    final msg = msgMaker() as ServerMessage;
    msg.readBytes(data);
    return msg;
  }
}

class MessageFramer {
  final _reader = ByteDataReader();
  MessageFrame messageInProgress = MessageFrame();
  final messageQueue = Queue<MessageFrame>();

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
        messageInProgress = MessageFrame();
        evaluateNextMessage = true;
      }
    }
  }

  bool get hasMessage => messageQueue.isNotEmpty;

  MessageFrame popMessage() {
    return messageQueue.removeFirst();
  }
}
