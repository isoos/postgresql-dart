import 'dart:typed_data';

import 'package:sasl_scram/sasl_scram.dart';

import '../buffer.dart';
import '../exceptions.dart';
import '../messages/client_messages.dart';
import '../messages/server_messages.dart';
import 'auth.dart';

/// Structure for SASL Authenticator
class PostgresSaslAuthenticator extends PostgresAuthenticator {
  final SaslAuthenticator authenticator;

  PostgresSaslAuthenticator(super.connection, this.authenticator);

  @override
  void onMessage(AuthenticationMessage message) {
    ClientMessage msg;
    switch (message.type) {
      case AuthenticationMessageType.sasl:
        final bytesToSend = authenticator.handleMessage(
            SaslMessageType.AuthenticationSASL, message.bytes);
        if (bytesToSend == null) {
          throw PgException('KindSASL: No bytes to send');
        }
        msg = SaslClientFirstMessage(bytesToSend, authenticator.mechanism.name);
        break;
      case AuthenticationMessageType.saslContinue:
        final bytesToSend = authenticator.handleMessage(
            SaslMessageType.AuthenticationSASLContinue, message.bytes);
        if (bytesToSend == null) {
          throw PgException('KindSASLContinue: No bytes to send');
        }
        msg = SaslClientLastMessage(bytesToSend);
        break;
      case AuthenticationMessageType.saslFinal:
        authenticator.handleMessage(
            SaslMessageType.AuthenticationSASLFinal, message.bytes);
        return;
      default:
        throw PgException(
            'Unsupported authentication type ${message.type}, closing connection.');
    }
    connection.sendMessage(msg);
  }
}

class SaslClientFirstMessage extends ClientMessage {
  final Uint8List bytesToSendToServer;
  final String mechanismName;

  SaslClientFirstMessage(this.bytesToSendToServer, this.mechanismName);

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    buffer.writeUint8(ClientMessageId.password);

    final encodedMechanismName = buffer.encodeString(mechanismName);
    final msgLength = bytesToSendToServer.length;
    // No Identifier bit + 4 byte counts (for whole length) + mechanism bytes + zero byte + 4 byte counts (for msg length) + msg bytes
    final length = 4 + encodedMechanismName.bytesLength + 1 + 4 + msgLength;

    buffer.writeUint32(length);
    buffer.writeEncodedString(encodedMechanismName);

    // do not add the msg byte count for whatever reason
    buffer.writeUint32(msgLength);
    buffer.write(bytesToSendToServer);
  }
}

class SaslClientLastMessage extends ClientMessage {
  Uint8List bytesToSendToServer;

  SaslClientLastMessage(this.bytesToSendToServer);

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    buffer.writeUint8(ClientMessageId.password);

    // No Identifier bit + 4 byte counts (for msg length) + msg bytes
    final length = 4 + bytesToSendToServer.length;

    buffer.writeUint32(length);
    buffer.write(bytesToSendToServer);
  }
}
