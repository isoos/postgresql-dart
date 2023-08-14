import 'dart:convert';

import 'package:buffer/buffer.dart';

import '../client_messages.dart';
import '../encoded_string.dart';
import '../server_messages.dart';
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
  EncodedString? _authString;

  ClearMessage(String password, Encoding encoding) {     
    _authString = EncodedString(password, encoding);
  }

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.PasswordIdentifier);
    final length = 5 + _authString!.byteLength;
    buffer.writeUint32(length);
    _authString!.applyToBuffer(buffer);
  }
}
