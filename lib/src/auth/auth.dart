/// Source:  https://github.com/mongo-dart/mongo_dart/blob/c761839efbf47ec556f853dec85debb4cb9370f7/lib/src/auth/auth.dart

import 'package:crypto/crypto.dart';
import 'package:postgres/src/auth/sasl_authenticator.dart';
import 'package:sasl_scram/sasl_scram.dart';

import '../../postgres.dart';
import '../server_messages.dart';
import 'md5_authenticator.dart';

enum AuthenticationScheme { MD5, SCRAM_SHA_256 }

abstract class PostgresAuthenticator {
  static String? name;
  late final PostgreSQLConnection connection;

  PostgresAuthenticator(this.connection);

  void onMessage(AuthenticationMessage message);
}

PostgresAuthenticator createAuthenticator(PostgreSQLConnection connection, UsernamePasswordCredential credentials) {
  switch (connection.authenticationScheme) {
    case AuthenticationScheme.MD5:
      return MD5Authenticator(connection, credentials);
    case AuthenticationScheme.SCRAM_SHA_256:
      return PostgresSaslAuthenticator(connection, ScramAuthenticator('SCRAM-SHA-256', sha256, credentials));
    default:
      throw PostgreSQLException("Authenticator wasn't specified");
  }
}
