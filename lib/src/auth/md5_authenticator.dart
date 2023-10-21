import 'package:buffer/buffer.dart';
import 'package:crypto/crypto.dart';

import '../buffer.dart';
import '../client_messages.dart';
import '../server_messages.dart';
import 'auth.dart';

class MD5Authenticator extends PostgresAuthenticator {
  static final String name = 'MD5';

  MD5Authenticator(super.connection);

  @override
  void onMessage(AuthenticationMessage message) {
    final reader = ByteDataReader()..add(message.bytes);
    final salt = reader.read(4, copy: true);

    final authMessage =
        AuthMD5Message(connection.username!, connection.password!, salt);

    connection.sendMessage(authMessage);
  }
}

class AuthMD5Message extends ClientMessage {
  final String _hashedAuthString;

  AuthMD5Message._(this._hashedAuthString);
  factory AuthMD5Message(
      String username, String password, List<int> saltBytes) {
    final passwordHash = md5.convert('$password$username'.codeUnits).toString();
    final saltString = String.fromCharCodes(saltBytes);
    final md5Hash =
        md5.convert('$passwordHash$saltString'.codeUnits).toString();
    return AuthMD5Message._('md5$md5Hash');
  }

  @override
  void applyToBuffer(PgByteDataWriter buffer) {
    buffer.writeUint8(ClientMessage.passwordIdentifier);
    buffer.writeLengthEncodedString(_hashedAuthString);
  }
}
