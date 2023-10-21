import '../buffer.dart';
import '../client_messages.dart';
import '../server_messages.dart';
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
  final String _password;

  ClearMessage(this._password);

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.passwordIdentifier);
    buffer.writeLengthEncodedString(_password);
  }
}
