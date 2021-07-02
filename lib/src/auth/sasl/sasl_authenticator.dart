/// Source:  https://github.com/mongo-dart/mongo_dart/blob/c761839efbf47ec556f853dec85debb4cb9370f7/lib/src/auth/sasl_authenticator.dart

// (The MIT License)
//
// Copyright (c) 2012 Vadim Tsushko (vadimtsushko@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// 'Software'), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import '../../../postgres.dart';
import '../../client_messages.dart';
import '../../server_messages.dart';
import '../../utf8_backed_string.dart';
import '../auth.dart';

abstract class SaslMechanism {
  String get name;

  SaslStep initialize(PostgreSQLConnection connection);
}

abstract class SaslStep {
  Uint8List bytesToSendToServer;
  bool isComplete = false;

  SaslStep(this.bytesToSendToServer, {this.isComplete = false});

  SaslStep transition(SaslConversation conversation, List<int> bytesReceivedFromServer);
}

class SaslConversation {
  PostgreSQLConnection connection;

  SaslConversation(this.connection);
}

/// Structure for SASL Authenticator
abstract class SaslAuthenticator extends Authenticator {
  static const int DefaultNonceLength = 24;

  SaslMechanism mechanism;
  late SaslStep currentStep;
  late SaslConversation conversation;

  SaslAuthenticator(PostgreSQLConnection connection, this.mechanism) : super(connection);

  @override
  void init() {
    conversation = SaslConversation(connection);
  }

  @override
  void onMessage(AuthenticationMessage message) {
    ClientMessage msg;
    switch (message.type) {
      case AuthenticationMessage.KindSASL:
        currentStep = mechanism.initialize(connection);
        msg = SaslClientFirstMessage(currentStep, mechanism);
        break;
      case AuthenticationMessage.KindSASLContinue:
        currentStep = currentStep.transition(conversation, message.bytes);
        msg = SaslClientLastMessage(currentStep);
        break;
      case AuthenticationMessage.KindSASLFinal:
        currentStep = currentStep.transition(conversation, message.bytes);
        return;
      default:
        throw PostgreSQLException('Unsupported authentication type ${message.type}, closing connection.');
    }
    connection.socket!.add(msg.asBytes());
  }
}

class SaslClientFirstMessage extends ClientMessage {
  SaslStep saslStep;
  SaslMechanism mechanism;

  SaslClientFirstMessage(this.saslStep, this.mechanism);

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.PasswordIdentifier);

    final utf8CachedMechanismName = UTF8BackedString(mechanism.name);

    final msgLength = saslStep.bytesToSendToServer.length;
    // No Identifier bit + 4 byte counts (for whole length) + mechanism bytes + zero byte + 4 byte counts (for msg length) + msg bytes
    final length = 4 + utf8CachedMechanismName.utf8Length + 1 + 4 + msgLength;

    buffer.writeUint32(length);
    applyStringToBuffer(utf8CachedMechanismName, buffer);

    // do not add the msg byte count for whatever reason
    buffer.writeUint32(msgLength);
    buffer.write(saslStep.bytesToSendToServer);
  }
}

class SaslClientLastMessage extends ClientMessage {
  SaslStep saslStep;

  SaslClientLastMessage(this.saslStep);

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.PasswordIdentifier);

    // No Identifier bit + 4 byte counts (for msg length) + msg bytes
    final length = 4 + saslStep.bytesToSendToServer.length;

    buffer.writeUint32(length);
    buffer.write(saslStep.bytesToSendToServer);
  }
}
