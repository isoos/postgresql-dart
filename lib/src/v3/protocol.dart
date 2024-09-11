import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:postgres/src/types/codec.dart';
import 'package:stream_channel/stream_channel.dart';

import '../buffer.dart';
import '../message_window.dart';
import '../messages/client_messages.dart';
import '../messages/server_messages.dart';
import '../messages/shared_messages.dart';

export '../messages/client_messages.dart';
export '../messages/server_messages.dart';
export '../messages/shared_messages.dart';

class AggregatedClientMessage extends ClientMessage {
  final List<ClientMessage> messages;

  AggregatedClientMessage(this.messages);

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    for (final cm in messages) {
      cm.applyToBuffer(buffer);
    }
  }

  @override
  String toString() {
    return 'Aggregated $messages';
  }
}

StreamChannelTransformer<Message, List<int>> messageTransformer(
    CodecContext codecContext) {
  return StreamChannelTransformer(
    _readMessages(codecContext),
    StreamSinkTransformer.fromHandlers(
      handleData: (message, out) {
        if (message is! ClientMessage) {
          out.addError(
              ArgumentError.value(
                  message, 'message', 'Must be a client message'),
              StackTrace.current);
          return;
        }

        out.add(message.asBytes(encoding: codecContext.encoding));
      },
    ),
  );
}

StreamTransformer<Uint8List, ServerMessage> _readMessages(
    CodecContext codecContext) {
  return StreamTransformer.fromBind((rawStream) {
    return Stream.multi((listener) {
      final framer = MessageFramer(codecContext);

      void emitFinishedMessages() {
        while (framer.hasMessage) {
          if (listener.isClosed) {
            break;
          }
          listener.addSync(framer.popMessage());
        }
      }

      Future<void> handleChunk(Uint8List bytes) async {
        await framer.addBytes(bytes);
        emitFinishedMessages();
      }

      // Don't cancel this subscription on error! If the listener wants that,
      // they'll unsubscribe in time after we forward it synchronously.
      final rawSubscription =
          rawStream.asyncMap(handleChunk).listen((_) {}, cancelOnError: false)
            ..onError(listener.addErrorSync)
            ..onDone(() async {
              await framer.addBytes(Uint8List(0));
              emitFinishedMessages();
              await listener.close();
            });

      listener.onCancel = () async {
        await rawSubscription.cancel();
      };
    });
  });
}
