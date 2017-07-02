import 'dart:typed_data';
import 'dart:io';
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

  int get bytesAvailable => packets.fold(0, (sum, v) => sum + v.lengthInBytes);
  List<Uint8List> packets = [];
  bool get hasReadHeader => type != null;
  int type;
  int expectedLength;

  bool get isComplete => data != null || expectedLength == 0;
  Uint8List data;

  ByteData consumeNextBytes(int length) {
    if (length == 0) {
      return null;
    }

    if (bytesAvailable >= length) {
      var firstPacket = packets.first;

      // The packet exactly matches the size of the bytes needed,
      // remove & return it.
      if (firstPacket.lengthInBytes == length) {
        packets.removeAt(0);
        return firstPacket.buffer
            .asByteData(firstPacket.offsetInBytes, firstPacket.lengthInBytes);
      }

      if (firstPacket.lengthInBytes > length) {
        // We have to split up this packet and remove & return the first portion of it,
        // and replace it with the second portion of it.
        var remainingOffset = firstPacket.offsetInBytes + length;
        var bytesNeeded =
            firstPacket.buffer.asByteData(firstPacket.offsetInBytes, length);
        var bytesRemaining = firstPacket.buffer
            .asUint8List(remainingOffset, firstPacket.lengthInBytes - length);
        packets.removeAt(0);
        packets.insert(0, bytesRemaining);

        return bytesNeeded;
      }

      // Otherwise, the first packet can't fill this message, but we know
      // we have enough packets overall to fulfill it. So we can build
      // a total buffer by accumulating multiple packets into that buffer.
      // Each packet gets removed along the way, except for the last one,
      // in which case if it has more bytes available, it gets replaced
      // with the remaining bytes.

      var builder = new BytesBuilder(copy: false);
      var bytesNeeded = length - builder.length;
      while (bytesNeeded > 0) {
        var packet = packets.removeAt(0);
        var bytesRemaining = packet.lengthInBytes;

        if (bytesRemaining <= bytesNeeded) {
          builder.add(packet.buffer
              .asUint8List(packet.offsetInBytes, packet.lengthInBytes));
        } else {
          builder.add(
              packet.buffer.asUint8List(packet.offsetInBytes, bytesNeeded));
          packets.insert(
              0,
              packet.buffer
                  .asUint8List(bytesNeeded, bytesRemaining - bytesNeeded));
        }

        bytesNeeded = length - builder.length;
      }

      return new Uint8List.fromList(builder.takeBytes()).buffer.asByteData();
    }

    return null;
  }

  int addBytes(Uint8List packet) {
    packets.add(packet);

    if (!hasReadHeader) {
      ByteData headerBuffer = consumeNextBytes(HeaderByteSize);
      if (headerBuffer == null) {
        return packet.lengthInBytes;
      }

      type = headerBuffer.getUint8(0);
      expectedLength = headerBuffer.getUint32(1) - 4;
    }

    if (expectedLength == 0) {
      return packet.lengthInBytes - bytesAvailable;
    }

    var body = consumeNextBytes(expectedLength);
    if (body == null) {
      return packet.lengthInBytes;
    }

    data = body.buffer.asUint8List(body.offsetInBytes, body.lengthInBytes);

    return packet.lengthInBytes - bytesAvailable;
  }

  ServerMessage get message {
    var msgMaker =
        messageTypeMap[type] ?? () => new UnknownMessage()..code = type;

    ServerMessage msg = msgMaker();
    msg.readBytes(data);
    return msg;
  }
}

class MessageFramer {
  MessageFrame messageInProgress = new MessageFrame();
  List<MessageFrame> messageQueue = [];

  void addBytes(Uint8List bytes) {
    var offsetIntoBytesRead = 0;

    do {
      var byteList = new Uint8List.view(bytes.buffer, offsetIntoBytesRead);
      offsetIntoBytesRead += messageInProgress.addBytes(byteList);

      if (messageInProgress.isComplete) {
        messageQueue.add(messageInProgress);
        messageInProgress = new MessageFrame();
      }
    } while (offsetIntoBytesRead != bytes.length);
  }

  bool get hasMessage => messageQueue.isNotEmpty;

  MessageFrame popMessage() {
    return messageQueue.removeAt(0);
  }
}
