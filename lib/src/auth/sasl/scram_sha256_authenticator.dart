/// Source:  https://github.com/mongo-dart/mongo_dart/blob/c761839efbf47ec556f853dec85debb4cb9370f7/lib/src/auth/scram_sha1_authenticator.dart

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

import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart' as crypto;

import '../../../postgres.dart';
import '../../server_messages.dart';
import '../auth.dart';
import 'sasl_authenticator.dart';

class ClientFirst extends SaslStep {
  String clientFirstMessageBare;
  UsernamePasswordCredential credential;
  String rPrefix;

  ClientFirst(Uint8List bytesToSendToServer, this.credential, this.clientFirstMessageBare, this.rPrefix)
      : super(bytesToSendToServer);

  @override
  SaslStep transition(SaslConversation conversation, List<int> bytesReceivedFromServer) {
    final serverFirstMessage = utf8.decode(bytesReceivedFromServer);

    final Map<String, dynamic> decodedMessage = parsePayload(serverFirstMessage);

    final r = decodedMessage['r'] as String?;
    if (r == null || !r.startsWith(rPrefix)) {
      throw PostgreSQLException('Server sent an invalid nonce.');
    }

    final s = decodedMessage['s'];
    final i = int.parse(decodedMessage['i'].toString());

    final gs2Header = 'n,,';
    final encodedHeader = base64.encode(utf8.encode(gs2Header));
    final channelBinding = 'c=$encodedHeader';
    final nonce = 'r=$r';
    final clientFinalMessageWithoutProof = '$channelBinding,$nonce';

    // final passwordDigest = md5DigestPassword(credential.username, credential.password);
    // TODO Mongo uses password digest, which isn't specified in the protocol (?)
    final passwordDigest = credential.password!;
    final salt = base64.decode(s.toString());

    final saltedPassword = hi(passwordDigest, salt, i);
    final clientKey = computeHMAC(saltedPassword, 'Client Key');
    final storedKey = h(clientKey);
    final authMessage = '$clientFirstMessageBare,$serverFirstMessage,$clientFinalMessageWithoutProof';
    final clientSignature = computeHMAC(storedKey, authMessage);
    final clientProof = xor(clientKey, clientSignature);
    final serverKey = computeHMAC(saltedPassword, 'Server Key');
    final serverSignature = computeHMAC(serverKey, authMessage);

    final base64clientProof = base64.encode(clientProof);
    final proof = 'p=$base64clientProof';
    final clientFinalMessage = '$clientFinalMessageWithoutProof,$proof';

    return ClientLast(_coerceUint8List(utf8.encode(clientFinalMessage)), serverSignature);
  }

  static Uint8List computeHMAC(Uint8List data, String key) {
    final sha256 = crypto.sha256;
    final hmac = crypto.Hmac(sha256, data);
    hmac.convert(utf8.encode(key));
    return Uint8List.fromList(hmac.convert(utf8.encode(key)).bytes);
  }

  static Uint8List h(Uint8List data) {
    return Uint8List.fromList(crypto.sha256.convert(data).bytes);
  }

  /*static String md5DigestPassword(username, password) {
    return crypto.md5.convert(utf8.encode('$username:postgresql:$password')).toString();
  }*/

  static Uint8List xor(Uint8List a, Uint8List b) {
    final result = <int>[];

    if (a.length > b.length) {
      for (var i = 0; i < b.length; i++) {
        result.add(a[i] ^ b[i]);
      }
    } else {
      for (var i = 0; i < a.length; i++) {
        result.add(a[i] ^ b[i]);
      }
    }

    return Uint8List.fromList(result);
  }

  static Uint8List hi(String password, Uint8List salt, int iterations) {
    final digest = (List<int> msg) {
      final hmac = crypto.Hmac(crypto.sha256, password.codeUnits);
      return Uint8List.fromList(hmac.convert(msg).bytes);
    };

    final newSalt = Uint8List.fromList(List.from(salt)..addAll([0, 0, 0, 1]));

    var ui = digest(newSalt);
    var u1 = ui;

    for (var i = 0; i < iterations - 1; i++) {
      u1 = digest(u1);
      ui = xor(ui, u1);
    }

    return ui;
  }
}

class ClientLast extends SaslStep {
  Uint8List serverSignature64;

  ClientLast(Uint8List bytesToSendToServer, this.serverSignature64) : super(bytesToSendToServer);

  @override
  SaslStep transition(SaslConversation conversation, List<int> bytesReceivedFromServer) {
    final Map<String, dynamic> decodedMessage = parsePayload(utf8.decode(bytesReceivedFromServer));
    final serverSignature = base64.decode(decodedMessage['v'].toString());

    if (!const IterableEquality().equals(serverSignature64, serverSignature)) {
      throw PostgreSQLException('Server signature was invalid.');
    }

    return CompletedStep();
  }
}

class CompletedStep extends SaslStep {
  CompletedStep() : super(Uint8List(0), isComplete: true);

  @override
  SaslStep transition(SaslConversation conversation, List<int> bytesReceivedFromServer) {
    throw PostgreSQLException('Sasl conversation has completed');
  }
}

Uint8List _coerceUint8List(List<int> list) => list is Uint8List ? list : Uint8List.fromList(list);

class ScramSha256Mechanism extends SaslMechanism {
  final UsernamePasswordCredential credential;
  final RandomStringGenerator randomStringGenerator;

  ScramSha256Mechanism(this.credential, this.randomStringGenerator);

  @override
  SaslStep initialize(PostgreSQLConnection connection) {
    if (credential.username == null) {
      throw PostgreSQLException('Username is empty on initialization');
    }

    final gs2Header = 'n,,';
    final username = 'n=*'; //Can replace "*" with "${prepUsername(credential.username!)}", if needed

    // List<int> cNonce;
    // final rnd = Random();
    // cNonce = List<int>.generate(SaslAuthenticator.DefaultNonceLength, (i) => rnd.nextInt(256));

    final r = randomStringGenerator.generate(SaslAuthenticator.DefaultNonceLength); // TODO may want to use above method and exclude ","

    final nonce = 'r=$r';

    final clientFirstMessageBare = '$username,$nonce';
    final clientFirstMessage = '$gs2Header$clientFirstMessageBare';

    return ClientFirst(_coerceUint8List(utf8.encode(clientFirstMessage)), credential, clientFirstMessageBare, r);
  }

  String prepUsername(String username) => username.replaceAll('=', '=3D').replaceAll(',', '=2C');

  @override
  String get name => ScramSha256Authenticator.name;
}

class ScramSha256Authenticator extends SaslAuthenticator {
  static String name = 'SCRAM-SHA-256';

  ScramSha256Authenticator(PostgreSQLConnection connection, UsernamePasswordCredential credential)
      : super(connection, ScramSha256Mechanism(credential, CryptoStrengthStringGenerator()));

  @override
  void onMessage(AuthenticationMessage message) {
    super.onMessage(message);
  }
}
