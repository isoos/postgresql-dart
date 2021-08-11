import 'package:crypto/crypto.dart';
import 'package:sasl_scram/sasl_scram.dart';

import '../../postgres.dart';
import '../server_messages.dart';
import 'md5_authenticator.dart';
import 'sasl_authenticator.dart';

enum AuthenticationScheme { MD5, SCRAM_SHA_256 }

abstract class PostgresAuthenticator {
  static String? name;
  late final PostgreSQLConnection connection;

  PostgresAuthenticator(this.connection);

  void onMessage(AuthenticationMessage message);
}

PostgresAuthenticator createAuthenticator(PostgreSQLConnection connection,
    AuthenticationScheme authenticationScheme) {
  switch (authenticationScheme) {
    case AuthenticationScheme.MD5:
      return MD5Authenticator(connection);
    case AuthenticationScheme.SCRAM_SHA_256:
      final credentials = UsernamePasswordCredential(
          username: connection.username, password: connection.password);
      return PostgresSaslAuthenticator(
          connection, ScramAuthenticator('SCRAM-SHA-256', sha256, credentials));
    default:
      throw PostgreSQLException("Authenticator wasn't specified");
  }
}
