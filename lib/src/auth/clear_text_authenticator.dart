import 'package:buffer/buffer.dart';

import '../client_messages.dart';
import '../server_messages.dart';
import '../utf8_backed_string.dart';
import 'auth.dart';

class ClearAuthenticator extends PostgresAuthenticator {
  ClearAuthenticator(super.connection);

  @override
  void onMessage(AuthenticationMessage message) {
    final authMessage = ClearMessage(connection.password!);
    connection.sendMessage(authMessage);
  }
}

class ClearMessage extends ClientMessage {
  UTF8BackedString? _authString;

  ClearMessage(String password) {
    _authString = UTF8BackedString(password);
  }

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.PasswordIdentifier);
    final length = 5 + _authString!.utf8Length;
    buffer.writeUint32(length);
    _authString!.applyToBuffer(buffer);
  }
}
