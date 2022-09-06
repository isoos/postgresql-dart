import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:postgres/messages.dart';
import 'package:postgres/postgres.dart';
import 'package:postgres/src/message_window.dart';
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

  test('Identify CopyDoneMessage with length equals size length (min)', () {
    // min length
    final length = 4;
    final bytes = Uint8List.fromList(
        [SharedMessages.copyDoneIdentifier, 0, 0, 0, length]);
    framer.addBytes(bytes);

    final message = framer.messageQueue.toList().first;
    expect(message, isA<CopyDoneMessage>());
    expect((message as CopyDoneMessage).length, length);
  });

  test('Identify CopyDoneMessage when length larger than size length', () {
    final length = 255;
    final bytes = Uint8List.fromList([
      SharedMessages.copyDoneIdentifier,
      length,
      length,
      length,
      length,
    ]);
    framer.addBytes(bytes);

    final message = framer.messageQueue.toList().first;
    expect(message, isA<CopyDoneMessage>());
    expect((message as CopyDoneMessage).length, 4294967295); // i.e. 2^32 - 1
  });

  test('Adds XLogDataMessage to queue', () {
    final bits64 = (ByteData(8)..setUint64(0, 42)).buffer.asUint8List();

    final xlogDataBytes = <int>[
      ReplicationMessage.xLogDataIdentifier,
      ...bits64,
      ...bits64,
      ...bits64,
      ...bits64
    ];
    final length = ByteData(4)..setUint32(0, xlogDataBytes.length + 4);
    final copyDataBytes = <int>[
      100,
      ...length.buffer.asUint8List(),
      ...xlogDataBytes,
    ];

    framer.addBytes(Uint8List.fromList(copyDataBytes));
    final message = framer.messageQueue.toList().first;
    expect(message, isA<XLogDataMessage>());
  });

  test('Adds XLogDataLogicalMessage to queue', () {
    framer = MessageFramer(ReplicationMode.logical);
    final bits64 = (ByteData(8)..setUint64(0, 42)).buffer.asUint8List();

    final xlogDataBytes = <int>[
      ReplicationMessage.xLogDataIdentifier,
      ...bits64,
      ...bits64,
      ...bits64,
      ...bits64
    ];
    final length = ByteData(4)..setUint32(0, xlogDataBytes.length + 4);
    final copyDataBytes = <int>[
      100,
      ...length.buffer.asUint8List(),
      ...xlogDataBytes,
    ];

    framer.addBytes(Uint8List.fromList(copyDataBytes));
    final message = framer.messageQueue.toList().first;
    expect(message, isA<XLogDataLogicalMessage>());

    flush(framer);
  });

  test('Adds PrimaryKeepAliveMessage to queue', () {
    final bits64 = (ByteData(8)..setUint64(0, 42)).buffer.asUint8List();

    final xlogDataBytes = <int>[
      ReplicationMessage.primaryKeepAliveIdentifier,
      ...bits64,
      ...bits64,
      0,
    ];
    final length = ByteData(4)..setUint32(0, xlogDataBytes.length + 4);
    final copyDataBytes = <int>[
      100,
      ...length.buffer.asUint8List(),
      ...xlogDataBytes,
    ];

    framer.addBytes(Uint8List.fromList(copyDataBytes));
    final message = framer.messageQueue.toList().first;
    expect(message, isA<PrimaryKeepAliveMessage>());
  });

  test('Adds raw CopyDataMessage for unknown stream message', () {
    final xlogDataBytes = <int>[
      -1, // unknown id
    ];
    final length = ByteData(4)..setUint32(0, xlogDataBytes.length + 4);
    final copyDataBytes = <int>[
      100,
      ...length.buffer.asUint8List(),
      ...xlogDataBytes,
    ];

    framer.addBytes(Uint8List.fromList(copyDataBytes));
    final message = framer.messageQueue.toList().first;
    expect(message, isA<CopyDataMessage>());
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
