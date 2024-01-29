import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:async/async.dart';
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
    Encoding encoding) {
  return StreamChannelTransformer(
    _readMessages(encoding),
    StreamSinkTransformer.fromHandlers(
      handleData: (message, out) {
        if (message is! ClientMessage) {
          out.addError(
              ArgumentError.value(
                  message, 'message', 'Must be a client message'),
              StackTrace.current);
          return;
        }

        out.add(message.asBytes(encoding: encoding));
      },
    ),
  );
}

StreamTransformer<Uint8List, ServerMessage> _readMessages(Encoding encoding) {
  return StreamTransformer.fromBind((rawStream) {
    return Stream.multi((listener) {
      final framer = MessageFramer(encoding);

      var paused = false;

      void emitFinishedMessages() {
        while (framer.hasMessage) {
          listener.addSync(framer.popMessage());

          if (paused) break;
        }
      }

      void handleChunk(Uint8List bytes) {
        framer.addBytes(bytes);
        emitFinishedMessages();
      }

      // Don't cancel this subscription on error! If the listener wants that,
      // they'll unsubscribe in time after we forward it synchronously.
      final rawSubscription =
          rawStream.listen(handleChunk, cancelOnError: false)
            ..onError(listener.addErrorSync)
            ..onDone(listener.closeSync);

      listener.onPause = () {
        paused = true;
        rawSubscription.pause();
      };

      listener.onResume = () {
        paused = false;
        emitFinishedMessages();

        if (!paused) {
          rawSubscription.resume();
        }
      };

      listener.onCancel = () {
        paused = true;
        rawSubscription.cancel();
      };
    });
  });
}
