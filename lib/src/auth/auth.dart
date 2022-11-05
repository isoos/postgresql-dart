import 'package:crypto/crypto.dart';
import 'package:sasl_scram/sasl_scram.dart';

import '../../postgres.dart';
import '../server_messages.dart';
import 'clear_text_authenticator.dart';
import 'md5_authenticator.dart';
import 'sasl_authenticator.dart';

enum AuthenticationScheme {
  md5,
  @Deprecated('Use md5 instead.')
  // ignore: constant_identifier_names
  MD5,
  scramSha256,
  @Deprecated('Use scramSha256 instead.')
  // ignore: constant_identifier_names
  SCRAM_SHA_256,
  clear,
  @Deprecated('Use clear instead.')
  // ignore: constant_identifier_names
  CLEAR,
}

abstract class PostgresAuthenticator {
  static String? name;
  late final PostgreSQLConnection connection;

  PostgresAuthenticator(this.connection);

  void onMessage(AuthenticationMessage message);
}

PostgresAuthenticator createAuthenticator(PostgreSQLConnection connection,
    AuthenticationScheme authenticationScheme) {
  switch (authenticationScheme) {
    case AuthenticationScheme.md5:
    // ignore: deprecated_member_use_from_same_package
    case AuthenticationScheme.MD5:
      return MD5Authenticator(connection);
    case AuthenticationScheme.scramSha256:
    // ignore: deprecated_member_use_from_same_package
    case AuthenticationScheme.SCRAM_SHA_256:
      final credentials = UsernamePasswordCredential(
          username: connection.username, password: connection.password);
      return PostgresSaslAuthenticator(
          connection, ScramAuthenticator('SCRAM-SHA-256', sha256, credentials));
    case AuthenticationScheme.clear:
    // ignore: deprecated_member_use_from_same_package
    case AuthenticationScheme.CLEAR:
      return ClearAuthenticator(connection);
    default:
      throw PostgreSQLException("Authenticator wasn't specified");
  }
}
