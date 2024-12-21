import 'dart:async';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:charcode/ascii.dart';
import 'package:postgres/src/types/codec.dart';

import 'buffer.dart';
import 'messages/server_messages.dart';
import 'messages/shared_messages.dart';

const int _headerByteSize = 5;

typedef _ServerMessageFn = FutureOr<ServerMessage> Function(
    PgByteDataReader reader, int length);

Map<int, _ServerMessageFn> _messageTypeMap = {
  49: (_, __) => ParseCompleteMessage(),
  50: (_, __) => BindCompleteMessage(),
  65: (r, _) => NotificationResponseMessage.parse(r),
  67: (r, _) => CommandCompleteMessage.parse(r),
  68: (r, _) => DataRowMessage.parse(r),
  69: ErrorResponseMessage.parse,
  75: (r, _) => BackendKeyMessage.parse(r),
  82: AuthenticationMessage.parse,
  83: (r, l) => ParameterStatusMessage.parse(r),
  84: (r, _) => RowDescriptionMessage.parse(r),
  87: (r, _) => CopyBothResponseMessage.parse(r),
  90: ReadyForQueryMessage.parse,
  100: _parseCopyDataMessage,
  110: (_, __) => NoDataMessage(),
  116: (r, _) => ParameterDescriptionMessage.parse(r),
  $3: (_, __) => CloseCompleteMessage(),
  $N: NoticeMessage.parse,
};

class _BytesFrame {
  final int type;
  final int length;
  final Uint8List bytes;

  _BytesFrame(this.type, this.length, this.bytes);
}

StreamTransformer<Uint8List, ServerMessage> bytesToMessageParser() {
  return StreamTransformer<Uint8List, ServerMessage>.fromHandlers(
    handleData: (data, sink) {},
  );
}

final _emptyData = Uint8List(0);

class _BytesToFrameParser
    extends StreamTransformerBase<Uint8List, _BytesFrame> {
  final CodecContext _codecContext;

  _BytesToFrameParser(this._codecContext);

  @override
  Stream<_BytesFrame> bind(Stream<Uint8List> stream) async* {
    final reader = PgByteDataReader(codecContext: _codecContext);

    int? type;
    int expectedLength = 0;

    await for (final bytes in stream) {
      reader.add(bytes);

      while (true) {
        if (type == null && reader.remainingLength >= _headerByteSize) {
          type = reader.readUint8();
          expectedLength = reader.readUint32() - 4;
        }

        // special case
        if (type == SharedMessageId.copyDone) {
          // unlike other messages, CopyDoneMessage only takes the length as an
          // argument (must be the full length including the length bytes)
          yield _BytesFrame(type!, expectedLength, _emptyData);
          type = null;
          expectedLength = 0;
          continue;
        }

        if (type != null && expectedLength <= reader.remainingLength) {
          final data = reader.read(expectedLength);
          yield _BytesFrame(type, expectedLength, data);
          type = null;
          expectedLength = 0;
          continue;
        }

        break;
      }
    }
  }
}

class BytesToMessageParser
    extends StreamTransformerBase<Uint8List, ServerMessage> {
  final CodecContext _codecContext;

  BytesToMessageParser(this._codecContext);

  @override
  Stream<ServerMessage> bind(Stream<Uint8List> stream) {
    return stream
        .transform(_BytesToFrameParser(_codecContext))
        .asyncMap((frame) async {
      // special case
      if (frame.type == SharedMessageId.copyDone) {
        // unlike other messages, CopyDoneMessage only takes the length as an
        // argument (must be the full length including the length bytes)
        return CopyDoneMessage(frame.length + 4);
      }

      final msgMaker = _messageTypeMap[frame.type];
      if (msgMaker == null) {
        return UnknownMessage(frame.type, frame.bytes);
      }

      return await msgMaker(
          PgByteDataReader(codecContext: _codecContext)..add(frame.bytes),
          frame.bytes.length);
    });
  }
}

/// Copy Data message is a wrapper around data stream messages
/// such as replication messages.
/// Returns a [ReplicationMessage] if the message contains such message.
/// Otherwise, it'll just return the provided bytes as [CopyDataMessage].
Future<ServerMessage> _parseCopyDataMessage(
    PgByteDataReader reader, int length) async {
  final code = reader.readUint8();
  if (code == ReplicationMessageId.primaryKeepAlive) {
    return PrimaryKeepAliveMessage.parse(reader);
  } else if (code == ReplicationMessageId.xLogData) {
    return XLogDataMessage.parse(
      reader.read(length - 1),
      reader.encoding,
      codecContext: reader.codecContext,
    );
  } else {
    final bb = BytesBuffer();
    bb.addByte(code);
    bb.add(reader.read(length - 1));
    return CopyDataMessage(bb.toBytes());
  }
}
