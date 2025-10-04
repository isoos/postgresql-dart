import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../buffer.dart';
import '../exceptions.dart';
import '../messages/client_messages.dart';
import '../messages/server_messages.dart';
import 'auth.dart';

final _random = Random.secure();

/// Structure for SASL Authenticator
class PostgresSaslAuthenticator extends PostgresAuthenticator {
  PostgresSaslAuthenticator(super.connection);

  late final _authenticator = _ScramSha256Authenticator(
    username: connection.username ?? '',
    password: connection.password ?? '',
  );

  @override
  void onMessage(AuthenticationMessage message) {
    ClientMessage? msg;
    switch (message.type) {
      case AuthenticationMessageType.sasl:
        // Server sends list of supported mechanisms
        final bytesToSend = _authenticator.generateClientFirstMessage();
        msg = SaslClientFirstMessage(bytesToSend, 'SCRAM-SHA-256');
        break;
      case AuthenticationMessageType.saslContinue:
        // Server sends server-first-message
        final bytesToSend = _authenticator.processServerFirstMessage(
          message.bytes,
        );
        msg = SaslClientLastMessage(bytesToSend);
        break;
      case AuthenticationMessageType.saslFinal:
        // Server sends server-final-message
        _authenticator.verifyServerFinalMessage(message.bytes);
        return;
      default:
        throw PgException(
          'Unsupported authentication type ${message.type}, closing connection.',
        );
    }
    connection.sendMessage(msg);
  }
}

/// SCRAM-SHA-256 authenticator implementation
class _ScramSha256Authenticator {
  final String username;
  final String password;

  late String _clientNonce;
  late String _clientFirstMessageBare;
  String? _serverNonce;
  String? _salt;
  int? _iterations;
  String? _authMessage;

  _ScramSha256Authenticator({required this.username, required this.password});

  /// Generate client-first-message
  Uint8List generateClientFirstMessage() {
    _clientNonce = base64.encode(
      List<int>.generate(24, (_) => _random.nextInt(256)),
    );

    final encodedUsername = username
        .replaceAll('=', '=3D')
        .replaceAll(',', '=2C');
    _clientFirstMessageBare = 'n=$encodedUsername,r=$_clientNonce';

    // client-first-message: GS2 header + client-first-message-bare
    // GS2 header: "n,," (no channel binding)
    final clientFirstMessage = 'n,,$_clientFirstMessageBare';

    return utf8.encode(clientFirstMessage);
  }

  /// Process server-first-message and generate client-final-message
  Uint8List processServerFirstMessage(Uint8List serverFirstMessageBytes) {
    final serverFirstMessage = utf8.decode(serverFirstMessageBytes);

    // Parse server-first-message: r=<nonce>,s=<salt>,i=<iteration-count>
    final parts = _parseMessage(serverFirstMessage);

    _serverNonce = parts['r'];
    _salt = parts['s'];
    _iterations = int.parse(parts['i'] ?? '0');

    if (_serverNonce == null || !_serverNonce!.startsWith(_clientNonce)) {
      throw PgException('Server nonce does not start with client nonce');
    }

    // Build client-final-message-without-proof
    final channelBinding = 'c=${base64.encode(utf8.encode('n,,'))}';
    final clientFinalMessageWithoutProof = '$channelBinding,r=$_serverNonce';

    // Calculate auth message
    _authMessage =
        '$_clientFirstMessageBare,$serverFirstMessage,$clientFinalMessageWithoutProof';

    // Calculate client proof
    final saltedPassword = _hi(
      utf8.encode(password),
      base64.decode(_salt!),
      _iterations!,
    );

    final clientKey = _hmac(saltedPassword, utf8.encode('Client Key'));
    final storedKey = sha256.convert(clientKey).bytes;
    final clientSignature = _hmac(storedKey, utf8.encode(_authMessage!));

    final clientProof = Uint8List(clientKey.length);
    for (var i = 0; i < clientKey.length; i++) {
      clientProof[i] = clientKey[i] ^ clientSignature[i];
    }

    // Build client-final-message
    final clientFinalMessage =
        '$clientFinalMessageWithoutProof,p=${base64.encode(clientProof)}';

    return Uint8List.fromList(utf8.encode(clientFinalMessage));
  }

  /// Verify server-final-message
  void verifyServerFinalMessage(Uint8List serverFinalMessageBytes) {
    final serverFinalMessage = utf8.decode(serverFinalMessageBytes);

    // Parse server-final-message: v=<verifier> or e=<error>
    final parts = _parseMessage(serverFinalMessage);

    if (parts.containsKey('e')) {
      throw PgException('SCRAM authentication failed: ${parts['e']}');
    }

    final serverSignatureB64 = parts['v'];
    if (serverSignatureB64 == null) {
      throw PgException('Server final message missing verifier');
    }

    // Calculate expected server signature
    final saltedPassword = _hi(
      utf8.encode(password),
      base64.decode(_salt!),
      _iterations!,
    );

    final serverKey = _hmac(saltedPassword, utf8.encode('Server Key'));
    final serverSignature = _hmac(serverKey, utf8.encode(_authMessage!));

    // Verify server signature
    final expectedSignature = base64.encode(serverSignature);
    if (serverSignatureB64 != expectedSignature) {
      throw PgException('Server signature verification failed');
    }
  }

  /// Parse SASL message into key-value pairs
  Map<String, String> _parseMessage(String message) {
    final result = <String, String>{};
    final parts = message.split(',');

    for (final part in parts) {
      final index = part.indexOf('=');
      if (index > 0) {
        final key = part.substring(0, index);
        final value = part.substring(index + 1);
        result[key] = value;
      }
    }

    return result;
  }

  /// HMAC-SHA256
  List<int> _hmac(List<int> key, List<int> message) {
    final hmacSha256 = Hmac(sha256, key);
    return hmacSha256.convert(message).bytes;
  }

  /// PBKDF2 (Hi function): HMAC iterated i times
  List<int> _hi(List<int> password, List<int> salt, int iterations) {
    // First iteration: HMAC(password, salt + INT(1))
    final saltWithCount = [...salt, 0, 0, 0, 1];
    var u = _hmac(password, saltWithCount);
    final result = List<int>.from(u);

    // Remaining iterations
    for (var i = 1; i < iterations; i++) {
      u = _hmac(password, u);
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
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
