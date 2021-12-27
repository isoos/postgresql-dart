import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:postgres/src/message_window.dart';
import 'package:postgres/src/server_messages.dart';
import 'package:test/test.dart';

void main() {
  late MessageFramer framer;
  setUp(() {
    framer = MessageFramer();
  });

  tearDown(() {
    flush(framer);
  });

  test('Perfectly sized message in one buffer', () {
    framer.addBytes(bufferWithMessages([
      messageWithBytes([1, 2, 3], 1)
    ]));

    final messages = framer.messageQueue.toList();
    expect(messages, [
      UnknownMessage(1, Uint8List.fromList([1, 2, 3])),
    ]);
  });

  test('Two perfectly sized messages in one buffer', () {
    framer.addBytes(bufferWithMessages([
      messageWithBytes([1, 2, 3], 1),
      messageWithBytes([1, 2, 3, 4], 2)
    ]));

    final messages = framer.messageQueue.toList();
    expect(messages, [
      UnknownMessage(1, Uint8List.fromList([1, 2, 3])),
      UnknownMessage(2, Uint8List.fromList([1, 2, 3, 4])),
    ]);
  });

  test('Header fragment', () {
    final message = messageWithBytes([1, 2, 3], 1);
    final fragments = fragmentedMessageBuffer(message, 2);
    framer.addBytes(fragments.first);
    expect(framer.messageQueue, isEmpty);

    framer.addBytes(fragments.last);

    final messages = framer.messageQueue.toList();
    expect(messages, [
      UnknownMessage(1, Uint8List.fromList([1, 2, 3]))
    ]);
  });

  test('Two header fragments', () {
    final message = messageWithBytes([1, 2, 3], 1);
    final fragments = fragmentedMessageBuffer(message, 2);
    final moreFragments = fragmentedMessageBuffer(fragments.first, 1);

    framer.addBytes(moreFragments.first);
    expect(framer.messageQueue, isEmpty);

    framer.addBytes(moreFragments.last);
    expect(framer.messageQueue, isEmpty);

    framer.addBytes(fragments.last);

    final messages = framer.messageQueue.toList();
    expect(messages, [
      UnknownMessage(1, Uint8List.fromList([1, 2, 3])),
    ]);
  });

  test('One message + header fragment', () {
    final message1 = messageWithBytes([1, 2, 3], 1);
    final message2 = messageWithBytes([2, 2, 3], 2);
    final message2Fragments = fragmentedMessageBuffer(message2, 3);

    framer.addBytes(bufferWithMessages([message1, message2Fragments.first]));

    expect(framer.messageQueue.length, 1);

    framer.addBytes(message2Fragments.last);

    final messages = framer.messageQueue.toList();
    expect(messages, [
      UnknownMessage(1, Uint8List.fromList([1, 2, 3])),
      UnknownMessage(2, Uint8List.fromList([2, 2, 3])),
    ]);
  });

  test('Message + header, missing rest of buffer', () {
    final message1 = messageWithBytes([1, 2, 3], 1);
    final message2 = messageWithBytes([2, 2, 3], 2);
    final message2Fragments = fragmentedMessageBuffer(message2, 5);

    framer.addBytes(bufferWithMessages([message1, message2Fragments.first]));

    expect(framer.messageQueue.length, 1);

    framer.addBytes(message2Fragments.last);

    final messages = framer.messageQueue.toList();
    expect(messages, [
      UnknownMessage(1, Uint8List.fromList([1, 2, 3])),
      UnknownMessage(2, Uint8List.fromList([2, 2, 3])),
    ]);
  });

  test('Message body spans two packets', () {
    final message = messageWithBytes([1, 2, 3, 4, 5, 6, 7], 1);
    final fragments = fragmentedMessageBuffer(message, 8);
    framer.addBytes(fragments.first);
    expect(framer.messageQueue, isEmpty);

    framer.addBytes(fragments.last);

    final messages = framer.messageQueue.toList();
    expect(messages, [
      UnknownMessage(1, Uint8List.fromList([1, 2, 3, 4, 5, 6, 7])),
    ]);
  });

  test(
      'Message spans two packets, started in a packet that contained another message',
      () {
    final earlierMessage = messageWithBytes([1, 2], 0);
    final message = messageWithBytes([1, 2, 3, 4, 5, 6, 7], 1);

    framer.addBytes(bufferWithMessages(
        [earlierMessage, fragmentedMessageBuffer(message, 8).first]));
    expect(framer.messageQueue, hasLength(1));

    framer.addBytes(fragmentedMessageBuffer(message, 8).last);

    final messages = framer.messageQueue.toList();
    expect(messages, [
      UnknownMessage(0, Uint8List.fromList([1, 2])),
      UnknownMessage(1, Uint8List.fromList([1, 2, 3, 4, 5, 6, 7]))
    ]);
  });

  test('Message spans three packets, only part of header in the first', () {
    final earlierMessage = messageWithBytes([1, 2], 0);
    final message =
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

    final messages = framer.messageQueue.toList();
    expect(messages, [
      UnknownMessage(0, Uint8List.fromList([1, 2])),
      UnknownMessage(
          1, Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])),
    ]);
  });

  test('Frame with no data', () {
    framer.addBytes(bufferWithMessages([messageWithBytes([], 10)]));

    final messages = framer.messageQueue.toList();
    expect(messages, [UnknownMessage(10, Uint8List(0))]);
  });
}

List<int> messageWithBytes(List<int> bytes, int messageID) {
  final buffer = BytesBuilder();
  buffer.addByte(messageID);
  final lengthBuffer = ByteData(4);
  lengthBuffer.setUint32(0, bytes.length + 4);
  buffer.add(lengthBuffer.buffer.asUint8List());
  buffer.add(bytes);
  return buffer.toBytes();
}

List<Uint8List> fragmentedMessageBuffer(List<int> message, int pivotPoint) {
  final l1 = message.sublist(0, pivotPoint);
  final l2 = message.sublist(pivotPoint, message.length);
  return [castBytes(l1), castBytes(l2)];
}

Uint8List bufferWithMessages(List<List<int>> messages) {
  return Uint8List.fromList(messages.expand((l) => l).toList());
}

void flush(MessageFramer framer) {
  framer.messageQueue.clear();
  framer.addBytes(bufferWithMessages([
    messageWithBytes([1, 2, 3], 1)
  ]));

  final messages = framer.messageQueue.toList();
  expect(messages, [
    UnknownMessage(1, Uint8List.fromList([1, 2, 3])),
  ]);
}
