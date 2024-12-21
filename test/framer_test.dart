import 'dart:async';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:postgres/src/message_window.dart';
import 'package:postgres/src/messages/logical_replication_messages.dart';
import 'package:postgres/src/messages/server_messages.dart';
import 'package:postgres/src/messages/shared_messages.dart';
import 'package:postgres/src/types/codec.dart';
import 'package:test/test.dart';

void main() {
  Future<void> parse(Uint8List buffer, messages) async {
    expect(
      await Stream.fromIterable([buffer])
          .transform(BytesToMessageParser(CodecContext.withDefaults()))
          .toList(),
      messages,
    );

    expect(
      await Stream.fromIterable(buffer.expand((b) => [
                Uint8List.fromList([b])
              ]))
          .transform(BytesToMessageParser(CodecContext.withDefaults()))
          .toList(),
      messages,
    );

    for (var i = 1; i < buffer.length - 1; i++) {
      final splitBuffers = fragmentedMessageBuffer(buffer, i);
      expect(
        await Stream.fromIterable(splitBuffers)
            .transform(BytesToMessageParser(CodecContext.withDefaults()))
            .toList(),
        messages,
      );
    }
  }

  test('Perfectly sized message in one buffer', () async {
    await parse(
        bufferWithMessages([
          messageWithBytes([1, 2, 3], 1),
        ]),
        [
          UnknownMessage(1, Uint8List.fromList([1, 2, 3])),
        ]);
  });

  test('Two perfectly sized messages in one buffer', () async {
    await parse(
        bufferWithMessages([
          messageWithBytes([1, 2, 3], 1),
          messageWithBytes([1, 2, 3, 4], 2),
        ]),
        [
          UnknownMessage(1, Uint8List.fromList([1, 2, 3])),
          UnknownMessage(2, Uint8List.fromList([1, 2, 3, 4])),
        ]);
  });

  test('Header fragment', () async {
    await parse(
        bufferWithMessages([
          messageWithBytes([], 1), // frame with no data
          [1], // only a header fragment
        ]),
        [UnknownMessage(1, Uint8List.fromList([]))]);
  });

  test('Identify CopyDoneMessage with length equals size length (min)',
      () async {
    // min length
    final length = [0, 0, 0, 4]; // min length (4 bytes) as 32-bit
    final bytes = Uint8List.fromList([
      SharedMessageId.copyDone,
      ...length,
    ]);
    await parse(
        bytes, [isA<CopyDoneMessage>().having((m) => m.length, 'length', 4)]);
  });

  test('Identify CopyDoneMessage when length larger than size length',
      () async {
    final length = (ByteData(4)..setUint32(0, 42)).buffer.asUint8List();
    final bytes = Uint8List.fromList([
      SharedMessageId.copyDone,
      ...length,
    ]);

    await parse(
        bytes, [isA<CopyDoneMessage>().having((m) => m.length, 'length', 42)]);
  });

  test('Adds XLogDataMessage to queue', () async {
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

    await parse(Uint8List.fromList(copyDataBytes), [
      allOf(
        isA<XLogDataMessage>(),
        isNot(isA<XLogDataLogicalMessage>()),
      ),
    ]);
  });

  test('Adds XLogDataLogicalMessage with JsonMessage to queue', () async {
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

    await parse(Uint8List.fromList(copyDataMessage), [
      isA<XLogDataLogicalMessage>()
          .having((x) => x.message, 'message', isA<JsonMessage>()),
    ]);
  });

  test('Adds PrimaryKeepAliveMessage to queue', () async {
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

    await parse(
        Uint8List.fromList(copyDataMessage), [isA<PrimaryKeepAliveMessage>()]);
  });

  test('Adds raw CopyDataMessage for unknown stream message', () async {
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

    await parse(Uint8List.fromList(copyDataMessage), [isA<CopyDataMessage>()]);
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
