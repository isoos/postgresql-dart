import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:postgres/src/message_window.dart';
import 'package:postgres/src/messages/logical_replication_messages.dart';
import 'package:postgres/src/messages/server_messages.dart';
import 'package:postgres/src/messages/shared_messages.dart';
import 'package:postgres/src/types/type_codec.dart';
import 'package:test/test.dart';

void main() {
  late MessageFramer framer;
  setUp(() {
    framer = MessageFramer(CodecContext.withDefaults());
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
    final length = [0, 0, 0, 4]; // min length (4 bytes) as 32-bit
    final bytes = Uint8List.fromList([
      SharedMessageId.copyDone,
      ...length,
    ]);
    framer.addBytes(bytes);

    final message = framer.messageQueue.toList().first;
    expect(message, isA<CopyDoneMessage>());
    expect((message as CopyDoneMessage).length, 4);
  });

  test('Identify CopyDoneMessage when length larger than size length', () {
    final length = (ByteData(4)..setUint32(0, 42)).buffer.asUint8List();
    final bytes = Uint8List.fromList([
      SharedMessageId.copyDone,
      ...length,
    ]);
    framer.addBytes(bytes);

    final message = framer.messageQueue.toList().first;
    expect(message, isA<CopyDoneMessage>());
    expect((message as CopyDoneMessage).length, 42);
  });

  test('Adds XLogDataMessage to queue', () {
    final bits64 = (ByteData(8)..setUint64(0, 42)).buffer.asUint8List();
    // random data bytes
    final dataBytes = [1, 2, 3, 4, 5, 6, 7, 8];

    /// This represent a raw [XLogDataMessage]
    final xlogDataMessage = <int>[
      ReplicationMessageId.xLogData,
      ...bits64, // walStart (64bit)
      ...bits64, // walEnd (64bit)
      ...bits64, // time (64bit)
      ...dataBytes // bytes (any)
    ];
    final length = ByteData(4)..setUint32(0, xlogDataMessage.length + 4);

    // this represents the [CopyDataMessage] which is a wrapper for [XLogDataMessage]
    // and such
    final copyDataBytes = <int>[
      SharedMessageId.copyData,
      ...length.buffer.asUint8List(),
      ...xlogDataMessage,
    ];

    framer.addBytes(Uint8List.fromList(copyDataBytes));
    final message = framer.messageQueue.toList().first;
    expect(message, isA<XLogDataMessage>());
    expect(message, isNot(isA<XLogDataLogicalMessage>()));
  });

  test('Adds XLogDataLogicalMessage with JsonMessage to queue', () {
    final bits64 = (ByteData(8)..setUint64(0, 42)).buffer.asUint8List();

    /// represent an empty json object so we should get a XLogDataLogicalMessage
    /// with JsonMessage as its message.
    final dataBytes = '{}'.codeUnits;

    /// This represent a raw [XLogDataMessage]
    final xlogDataMessage = <int>[
      ReplicationMessageId.xLogData,
      ...bits64, // walStart (64bit)
      ...bits64, // walEnd (64bit)
      ...bits64, // time (64bit)
      ...dataBytes, // bytes (any)
    ];

    final length = ByteData(4)..setUint32(0, xlogDataMessage.length + 4);

    /// this represents the [CopyDataMessage] in which [XLogDataMessage]
    /// is delivered per protocol
    final copyDataMessage = <int>[
      SharedMessageId.copyData,
      ...length.buffer.asUint8List(),
      ...xlogDataMessage,
    ];

    framer.addBytes(Uint8List.fromList(copyDataMessage));
    final message = framer.messageQueue.toList().first;
    expect(message, isA<XLogDataLogicalMessage>());
    expect((message as XLogDataLogicalMessage).message, isA<JsonMessage>());
  });

  test('Adds PrimaryKeepAliveMessage to queue', () {
    final bits64 = (ByteData(8)..setUint64(0, 42)).buffer.asUint8List();

    /// This represent a raw [PrimaryKeepAliveMessage]
    final xlogDataMessage = <int>[
      ReplicationMessageId.primaryKeepAlive,
      ...bits64, // walEnd (64bits)
      ...bits64, // time (64bits)
      0, // mustReply (1bit)
    ];
    final length = ByteData(4)..setUint32(0, xlogDataMessage.length + 4);

    /// This represents the [CopyDataMessage] in which [PrimaryKeepAliveMessage]
    /// is delivered per protocol
    final copyDataMessage = <int>[
      SharedMessageId.copyData,
      ...length.buffer.asUint8List(),
      ...xlogDataMessage,
    ];

    framer.addBytes(Uint8List.fromList(copyDataMessage));
    final message = framer.messageQueue.toList().first;
    expect(message, isA<PrimaryKeepAliveMessage>());
  });

  test('Adds raw CopyDataMessage for unknown stream message', () {
    final xlogDataBytes = <int>[
      -1, // unknown id
    ];

    final length = ByteData(4)..setUint32(0, xlogDataBytes.length + 4);

    /// This represents the [CopyDataMessage] in which data  is delivered per protocol
    /// typically contains [XLogData] and such but this tests unknown content
    final copyDataMessage = <int>[
      SharedMessageId.copyData,
      ...length.buffer.asUint8List(),
      ...xlogDataBytes,
    ];

    framer.addBytes(Uint8List.fromList(copyDataMessage));
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
