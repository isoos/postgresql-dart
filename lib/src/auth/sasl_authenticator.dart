import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:sasl_scram/sasl_scram.dart';

import '../../postgres.dart';
import '../client_messages.dart';
import '../server_messages.dart';
import '../utf8_backed_string.dart';
import 'auth.dart';

/// Structure for SASL Authenticator
class PostgresSaslAuthenticator extends PostgresAuthenticator {
  final SaslAuthenticator authenticator;

  PostgresSaslAuthenticator(
      PostgresAuthConnection connection, this.authenticator)
      : super(connection);

  @override
  void onMessage(AuthenticationMessage message) {
    ClientMessage msg;
    switch (message.type) {
      case AuthenticationMessage.KindSASL:
        final bytesToSend = authenticator.handleMessage(
            SaslMessageType.AuthenticationSASL, message.bytes);
        if (bytesToSend == null) {
          throw PostgreSQLException('KindSASL: No bytes to send');
        }
        msg = SaslClientFirstMessage(bytesToSend, authenticator.mechanism.name);
        break;
      case AuthenticationMessage.KindSASLContinue:
        final bytesToSend = authenticator.handleMessage(
            SaslMessageType.AuthenticationSASLContinue, message.bytes);
        if (bytesToSend == null) {
          throw PostgreSQLException('KindSASLContinue: No bytes to send');
        }
        msg = SaslClientLastMessage(bytesToSend);
        break;
      case AuthenticationMessage.KindSASLFinal:
        authenticator.handleMessage(
            SaslMessageType.AuthenticationSASLFinal, message.bytes);
        return;
      default:
        throw PostgreSQLException(
            'Unsupported authentication type ${message.type}, closing connection.');
    }
    connection.sendMessage(msg);
  }
}

class SaslClientFirstMessage extends ClientMessage {
  Uint8List bytesToSendToServer;
  String mechanismName;

  SaslClientFirstMessage(this.bytesToSendToServer, this.mechanismName);

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.PasswordIdentifier);

    final utf8CachedMechanismName = UTF8BackedString(mechanismName);

    final msgLength = bytesToSendToServer.length;
    // No Identifier bit + 4 byte counts (for whole length) + mechanism bytes + zero byte + 4 byte counts (for msg length) + msg bytes
    final length = 4 + utf8CachedMechanismName.utf8Length + 1 + 4 + msgLength;

    buffer.writeUint32(length);
    utf8CachedMechanismName.applyToBuffer(buffer);

    // do not add the msg byte count for whatever reason
    buffer.writeUint32(msgLength);
    buffer.write(bytesToSendToServer);
  }
}

class SaslClientLastMessage extends ClientMessage {
  Uint8List bytesToSendToServer;

  SaslClientLastMessage(this.bytesToSendToServer);

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.PasswordIdentifier);

    // No Identifier bit + 4 byte counts (for msg length) + msg bytes
    final length = 4 + bytesToSendToServer.length;

    buffer.writeUint32(length);
    buffer.write(bytesToSendToServer);
  }
}
