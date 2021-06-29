/// Source:  https://github.com/mongo-dart/mongo_dart/blob/c761839efbf47ec556f853dec85debb4cb9370f7/lib/src/auth/auth.dart

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

import 'dart:math';

import 'package:postgres/src/auth/sasl/scram_sha256_authenticator.dart';

import '../../postgres.dart';
import '../server_messages.dart';
import 'md5/md5_authenticator.dart';

enum AuthenticationScheme { MD5, SCRAM_SHA_256 }

abstract class Authenticator {
  static String? name;
  late final PostgreSQLConnection connection;

  Authenticator(this.connection);

  void init();

  void onMessage(AuthenticationMessage message);
}

Authenticator createAuthenticator(PostgreSQLConnection connection, UsernamePasswordCredential credentials) {
  switch (connection.authenticationScheme) {
    case AuthenticationScheme.MD5:
      return MD5Authenticator(credentials);
    // case AuthenticationScheme.SCRAM_SHA_256:
    //   return ScramSha256Authenticator(credentials);
    default:
      throw PostgreSQLException("Authenticator wasn't specified");
  }
}

class UsernamePasswordCredential {
  String? username;
  String? password; // TODO: Encrypt this to secureString
}

abstract class RandomStringGenerator {
  static const String allowedCharacters = '!"#\'\$%&()*+-./0123456789:;<=>?@'
  'ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~';
  String generate(int length);
}

class CryptoStrengthStringGenerator extends RandomStringGenerator {
  @override
  String generate(int length) {
    final random = Random.secure();
    final allowedCodeUnits = RandomStringGenerator.allowedCharacters.codeUnits;

    final max = allowedCodeUnits.length - 1;

    final randomString = <int>[];

    for (var i = 0; i < length; ++i) {
      randomString.add(allowedCodeUnits.elementAt(random.nextInt(max)));
    }

    return String.fromCharCodes(randomString);
  }
}

Map<String, String> parsePayload(String payload) {
  final dict = <String, String>{};
  final parts = payload.split(',');

  for (var i = 0; i < parts.length; i++) {
    final key = parts[i][0];
    final value = parts[i].substring(2);
    dict[key] = value;
  }

  return dict;
}
