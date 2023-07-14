import 'dart:convert';

import 'package:buffer/buffer.dart';
import 'package:crypto/crypto.dart';

import '../client_messages.dart';
import '../encoded_string.dart';
import '../server_messages.dart';
import 'auth.dart';

class MD5Authenticator extends PostgresAuthenticator {
  static final String name = 'MD5';

  MD5Authenticator(PostgresAuthConnection connection,Encoding encoding) : super(connection,encoding);

  @override
  void onMessage(AuthenticationMessage message) {
    final reader = ByteDataReader()..add(message.bytes);
    final salt = reader.read(4, copy: true);

    final authMessage =
        AuthMD5Message(connection.username!, connection.password!, salt,encoding);

    connection.sendMessage(authMessage);
  }
}

class AuthMD5Message extends ClientMessage {
  EncodedString? _hashedAuthString;

  AuthMD5Message(String username, String password, List<int> saltBytes,Encoding encoding) {
    final passwordHash = md5.convert('$password$username'.codeUnits).toString();
    final saltString = String.fromCharCodes(saltBytes);
    final md5Hash =
        md5.convert('$passwordHash$saltString'.codeUnits).toString();
        //TODO verificar se aqui tem que ser ascii em vez do charset padão da conexão
    _hashedAuthString = EncodedString('md5$md5Hash',encoding);
  }

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.PasswordIdentifier);
    final length = 5 + _hashedAuthString!.byteLength;
    buffer.writeUint32(length);
    _hashedAuthString!.applyToBuffer(buffer);
  }
}
