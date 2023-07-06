import 'dart:convert';

import 'package:buffer/buffer.dart';

import '../client_messages.dart';
import '../server_messages.dart';
import '../utf8_backed_string.dart';
import 'auth.dart';

class ClearAuthenticator extends PostgresAuthenticator {
  ClearAuthenticator(PostgresAuthConnection connection,Encoding encoding)
      : super(connection,encoding);
  

  @override
  void onMessage(AuthenticationMessage message) {
    final authMessage = ClearMessage(connection.password!, encoding);
    connection.sendMessage(authMessage);
  }
}

class ClearMessage extends ClientMessage {
  UTF8BackedString? _authString;

  ClearMessage(String password, Encoding encoding) {
      //TODO verificar se aqui tem que ser ascii em vez do charset padão da conexão
    _authString = UTF8BackedString(password, encoding);
  }

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.PasswordIdentifier);
    final length = 5 + _authString!.utf8Length;
    buffer.writeUint32(length);
    _authString!.applyToBuffer(buffer);
  }
}
