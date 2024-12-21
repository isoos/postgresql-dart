import 'package:async/async.dart';
import 'package:postgres/src/types/codec.dart';
import 'package:stream_channel/stream_channel.dart';

import '../buffer.dart';
import '../message_window.dart';
import '../messages/client_messages.dart';
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
    BytesToMessageParser(codecContext),
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
