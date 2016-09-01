part of postgres;

class _MessageFrame {
  static Map<int, Function> _messageTypeMap = {
    49 : () => new _ParseCompleteMessage(),
    50 : () => new _BindCompleteMessage(),
    67 : () => new _CommandCompleteMessage(),
    68 : () => new _DataRowMessage(),
    69 : () => new _ErrorResponseMessage(),

    75 : () => new _BackendKeyMessage(),

    82 : () => new _AuthenticationMessage(),
    83 : () => new _ParameterStatusMessage(),
    84 : () => new _RowDescriptionMessage(),

    90 : () => new _ReadyForQueryMessage(),
    116 : () => new _ParameterDescriptionMessage()
  };

  BytesBuilder _inputBuffer = new BytesBuilder(copy: false);
  int type;
  int expectedLength;

  bool get isComplete => data != null;
  Uint8List data;

  int addBytes(Uint8List bytes) {
    // If we just have the beginning of a packet, then consume the bytes and continue.
    if (_inputBuffer.length + bytes.length < 5) {

      _inputBuffer.add(bytes);
      return bytes.length;
    }

    // If we have enough data to get the header out, peek at that data and store it
    // This could be 5 if we haven't collected any data yet, or 1-4 if got a few bytes
    // from a previous packet. It can't be <= 0 though, as the first precondition
    // would have failed and we'd be right here.
    var countNeededFromIncomingToDetermineMessage = 5 - _inputBuffer.length;
    var headerBuffer = new Uint8List(5);
    if (countNeededFromIncomingToDetermineMessage < 5) {
      var takenBytes = _inputBuffer.takeBytes();
      headerBuffer.setRange(0, takenBytes.length, takenBytes);
    }
    headerBuffer.setRange(5 - countNeededFromIncomingToDetermineMessage, 5, new Uint8List.view(bytes.buffer, bytes.offsetInBytes, countNeededFromIncomingToDetermineMessage));

    var bufReader = new ByteData.view(headerBuffer.buffer);
    type = bufReader.getUint8(0);
    expectedLength = bufReader.getUint32(1) - 4; // Remove this length from the length needed to complete this message

    var offsetIntoIncomingBytes = countNeededFromIncomingToDetermineMessage;
    var byteBufferLengthRemaining = bytes.length - offsetIntoIncomingBytes;
    if (byteBufferLengthRemaining >= expectedLength) {
      _inputBuffer.add(new Uint8List.view(bytes.buffer, bytes.offsetInBytes + offsetIntoIncomingBytes, expectedLength));
      data = _inputBuffer.takeBytes();
      return offsetIntoIncomingBytes + expectedLength;
    }

    _inputBuffer.add(new Uint8List.view(bytes.buffer, bytes.offsetInBytes + offsetIntoIncomingBytes));
    return bytes.length;
  }

  _Message get message {
    var msgMaker = _messageTypeMap[type];
    if (msgMaker == null) {
      msgMaker = () {
        var msg = new _UnknownMessage()
            ..code = type;
        return msg;
      };
    }

    _Message msg = msgMaker();

    msg.readBytes(data);

    return msg;
  }
}

class _MessageFramer {
  _MessageFrame messageInProgress = new _MessageFrame();
  List<_MessageFrame> messageQueue = [];

  void addBytes(Uint8List bytes) {
    var offsetIntoBytesRead = 0;

    print("Receiving $bytes");
     do {
      offsetIntoBytesRead += messageInProgress.addBytes(new Uint8List.view(bytes.buffer, offsetIntoBytesRead));

      if (messageInProgress.isComplete) {
        messageQueue.add(messageInProgress);
        messageInProgress = new _MessageFrame();
      }
    } while (offsetIntoBytesRead != bytes.length);
  }

  bool get hasMessage => messageQueue.isNotEmpty;

  _MessageFrame popMessage() {
    return messageQueue.removeAt(0);
  }
}