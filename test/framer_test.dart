import 'package:postgres/src/message_window.dart';
import 'package:postgres/src/server_messages.dart';
import 'package:test/test.dart';
import 'dart:typed_data';
import 'dart:io';

void main() {
  MessageFramer framer;
  setUp(() {
    framer = new MessageFramer();
  });

  tearDown(() {
    flush(framer);
  });

  test("Perfectly sized message in one buffer", () {
    framer.addBytes(bufferWithMessages([
      messageWithBytes([1, 2, 3], 1)
    ]));

    var messages = framer.messageQueue.map((f) => f.message).toList();
    expect(messages, [
      new UnknownMessage()
        ..code = 1
        ..bytes = new Uint8List.fromList([1, 2, 3])
    ]);
  });

  test("Two perfectly sized messages in one buffer", () {
    framer.addBytes(bufferWithMessages([
      messageWithBytes([1, 2, 3], 1),
      messageWithBytes([1, 2, 3, 4], 2)
    ]));

    var messages = framer.messageQueue.map((f) => f.message).toList();
    expect(messages, [
      new UnknownMessage()
        ..code = 1
        ..bytes = new Uint8List.fromList([1, 2, 3]),
      new UnknownMessage()
        ..code = 2
        ..bytes = new Uint8List.fromList([1, 2, 3, 4])
    ]);
  });

  test("Header fragment", () {
    var message = messageWithBytes([1, 2, 3], 1);
    var fragments = fragmentedMessageBuffer(message, 2);
    framer.addBytes(fragments.first);
    expect(framer.messageQueue, isEmpty);

    framer.addBytes(fragments.last);

    var messages = framer.messageQueue.map((f) => f.message).toList();
    expect(messages, [
      new UnknownMessage()
        ..code = 1
        ..bytes = new Uint8List.fromList([1, 2, 3])
    ]);
  });

  test("Two header fragments", () {
    var message = messageWithBytes([1, 2, 3], 1);
    var fragments = fragmentedMessageBuffer(message, 2);
    var moreFragments = fragmentedMessageBuffer(fragments.first, 1);

    framer.addBytes(moreFragments.first);
    expect(framer.messageQueue, isEmpty);

    framer.addBytes(moreFragments.last);
    expect(framer.messageQueue, isEmpty);

    framer.addBytes(fragments.last);

    var messages = framer.messageQueue.map((f) => f.message).toList();
    expect(messages, [
      new UnknownMessage()
        ..code = 1
        ..bytes = new Uint8List.fromList([1, 2, 3])
    ]);
  });

  test("One message + header fragment", () {
    var message1 = messageWithBytes([1, 2, 3], 1);
    var message2 = messageWithBytes([2, 2, 3], 2);
    var message2Fragments = fragmentedMessageBuffer(message2, 3);

    framer.addBytes(bufferWithMessages([message1, message2Fragments.first]));

    expect(framer.messageQueue.length, 1);

    framer.addBytes(message2Fragments.last);

    var messages = framer.messageQueue.map((f) => f.message).toList();
    expect(messages, [
      new UnknownMessage()
        ..code = 1
        ..bytes = new Uint8List.fromList([1, 2, 3]),
      new UnknownMessage()
        ..code = 2
        ..bytes = new Uint8List.fromList([2, 2, 3]),
    ]);
  });

  test("Message + header, missing rest of buffer", () {
    var message1 = messageWithBytes([1, 2, 3], 1);
    var message2 = messageWithBytes([2, 2, 3], 2);
    var message2Fragments = fragmentedMessageBuffer(message2, 5);

    framer.addBytes(bufferWithMessages([message1, message2Fragments.first]));

    expect(framer.messageQueue.length, 1);

    framer.addBytes(message2Fragments.last);

    var messages = framer.messageQueue.map((f) => f.message).toList();
    expect(messages, [
      new UnknownMessage()
        ..code = 1
        ..bytes = new Uint8List.fromList([1, 2, 3]),
      new UnknownMessage()
        ..code = 2
        ..bytes = new Uint8List.fromList([2, 2, 3]),
    ]);
  });

  test("Message body spans two packets", () {
    var message = messageWithBytes([1, 2, 3, 4, 5, 6, 7], 1);
    var fragments = fragmentedMessageBuffer(message, 8);
    framer.addBytes(fragments.first);
    expect(framer.messageQueue, isEmpty);

    framer.addBytes(fragments.last);

    var messages = framer.messageQueue.map((f) => f.message).toList();
    expect(messages, [
      new UnknownMessage()
        ..code = 1
        ..bytes = new Uint8List.fromList([1, 2, 3, 4, 5, 6, 7])
    ]);
  });

  test(
      "Message spans two packets, started in a packet that contained another message",
      () {
    var earlierMessage = messageWithBytes([1, 2], 0);
    var message = messageWithBytes([1, 2, 3, 4, 5, 6, 7], 1);

    framer.addBytes(bufferWithMessages(
        [earlierMessage, fragmentedMessageBuffer(message, 8).first]));
    expect(framer.messageQueue, hasLength(1));

    framer.addBytes(fragmentedMessageBuffer(message, 8).last);

    var messages = framer.messageQueue.map((f) => f.message).toList();
    expect(messages, [
      new UnknownMessage()
        ..code = 0
        ..bytes = new Uint8List.fromList([1, 2]),
      new UnknownMessage()
        ..code = 1
        ..bytes = new Uint8List.fromList([1, 2, 3, 4, 5, 6, 7])
    ]);
  });

  test("Message spans three packets, only part of header in the first", () {
    var earlierMessage = messageWithBytes([1, 2], 0);
    var message =
        messageWithBytes([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], 1);

    framer.addBytes(bufferWithMessages(
        [earlierMessage, fragmentedMessageBuffer(message, 3).first]));
    expect(framer.messageQueue, hasLength(1));

    framer.addBytes(
        fragmentedMessageBuffer(fragmentedMessageBuffer(message, 3).last, 6)
            .first);
    expect(framer.messageQueue, hasLength(1));

    framer.addBytes(
        fragmentedMessageBuffer(fragmentedMessageBuffer(message, 3).last, 6)
            .last);

    var messages = framer.messageQueue.map((f) => f.message).toList();
    expect(messages, [
      new UnknownMessage()
        ..code = 0
        ..bytes = new Uint8List.fromList([1, 2]),
      new UnknownMessage()
        ..code = 1
        ..bytes =
            new Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])
    ]);
  });

  test("Frame with no data", () {
    framer.addBytes(bufferWithMessages([messageWithBytes([], 10)]));

    var messages = framer.messageQueue.map((f) => f.message).toList();
    expect(messages, [new UnknownMessage()..code = 10]);
  });
}

List<int> messageWithBytes(List<int> bytes, int messageID) {
  var buffer = new BytesBuilder();
  buffer.addByte(messageID);
  var lengthBuffer = new ByteData(4);
  lengthBuffer.setUint32(0, bytes.length + 4);
  buffer.add(lengthBuffer.buffer.asUint8List());
  buffer.add(bytes);
  return buffer.toBytes();
}

List<List<int>> fragmentedMessageBuffer(List<int> message, int pivotPoint) {
  var l1 = message.sublist(0, pivotPoint);
  var l2 = message.sublist(pivotPoint, message.length);
  return [l1, l2];
}

List<int> bufferWithMessages(List<List<int>> messages) {
  return new Uint8List.fromList(messages.expand((l) => l).toList());
}

flush(MessageFramer framer) {
  framer.messageQueue = [];
  framer.addBytes(bufferWithMessages([
    messageWithBytes([1, 2, 3], 1)
  ]));

  var messages = framer.messageQueue.map((f) => f.message).toList();
  expect(messages, [
    new UnknownMessage()
      ..code = 1
      ..bytes = new Uint8List.fromList([1, 2, 3])
  ]);
}
