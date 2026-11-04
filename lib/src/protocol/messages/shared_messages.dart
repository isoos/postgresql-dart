import 'dart:typed_data';

import '../buffer.dart';
import 'client_messages.dart';
import 'server_messages.dart';

/// Either a [ServerMessage] or a [ClientMessage].
abstract class Message {
  const Message();
}

abstract class ReplicationMessageId {
  static const int primaryKeepAlive = 107; // k
  static const int xLogData = 119; // w
  static const int hotStandbyFeedback = 104; // h
  static const int standbyStatusUpdate = 114; // r
}

/// An abstraction for all client and server replication messages
///
/// For more details, see [Streaming Replication Protocol][]
///
/// [Streaming Replication Protocol]: https://www.postgresql.org/docs/current/protocol-replication.html
abstract class ReplicationMessage {}

abstract class SharedMessageId {
  static const int copyDone = 99; // c
  static const int copyData = 100; // d
}

/// Messages that are shared between both the server and the client
///
/// For more details, see [Message Formats][]
///
/// [Message Formats]: https://www.postgresql.org/docs/current/protocol-message-formats.html
abstract class SharedMessage extends ClientMessage implements ServerMessage {}

/// A COPY data message.
class CopyDataMessage extends SharedMessage {
  /// Data that forms part of a COPY data stream. Messages sent from the backend
  /// will always correspond to single data rows, but messages sent by frontends
  /// might divide the data stream arbitrarily.
  final Uint8List bytes;

  CopyDataMessage(this.bytes);

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    buffer.writeUint8(SharedMessageId.copyData);
    buffer.writeInt32(bytes.length + 4);
    buffer.write(bytes);
  }
}

/// A COPY-complete indicator.
class CopyDoneMessage extends SharedMessage {
  ///  Length of message contents in bytes, including self.
  late final int length;

  CopyDoneMessage(this.length);

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    buffer.writeUint8(SharedMessageId.copyDone);
    buffer.writeInt32(length);
  }
}
