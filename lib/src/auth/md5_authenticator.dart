import 'dart:convert';

import 'package:buffer/buffer.dart';
import 'package:crypto/crypto.dart';

import '../buffer.dart';
import '../messages/client_messages.dart';
import '../messages/server_messages.dart';
import 'auth.dart';

class MD5Authenticator extends PostgresAuthenticator {
  static final String name = 'MD5';

  MD5Authenticator(super.connection);

  @override
  void onMessage(AuthenticationMessage message) {
    final reader = ByteDataReader()..add(message.bytes);
    final salt = reader.read(4, copy: true);

    final authMessage = AuthMD5Message(
      connection.username!,
      connection.password!,
      salt,
    );

    connection.sendMessage(authMessage);
  }
}

class AuthMD5Message extends ClientMessage {
  final String _hashedAuthString;

  AuthMD5Message._(this._hashedAuthString);
  factory AuthMD5Message(
    String username,
    String password,
    List<int> saltBytes,
  ) {
    // PostgreSQL computes this over the byte encoding of the credentials
    // (UTF-8), not over UTF-16 code units - using `.codeUnits` directly
    // would produce a different hash than the server for any non-ASCII
    // password or username.
    final passwordHash = md5.convert(utf8.encode('$password$username')).toString();
    final md5Hash = md5
        .convert([...utf8.encode(passwordHash), ...saltBytes])
        .toString();
    return AuthMD5Message._('md5$md5Hash');
  }

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    buffer.writeUint8(ClientMessageId.password);
    buffer.writeLengthEncodedString(_hashedAuthString);
  }
}
