import 'package:crypto/crypto.dart';
import 'package:sasl_scram/sasl_scram.dart';

import '../../messages.dart';
import 'clear_text_authenticator.dart';
import 'md5_authenticator.dart';
import 'sasl_authenticator.dart';

enum AuthenticationScheme {
  md5,
  scramSha256,
  clear,
}

/// A small interface to obtain the username and password used for a postgres
/// connection, as well as sending messages.
///
/// We want to share the authentication implementation in both the current
/// implementation and the implementation for the upcoming v3 API. As well as
/// both incompatible APIs are supported, we need this level of indirection so
/// that the auth mechanism can talk to both implementations.
class PostgresAuthConnection {
  final String? username;
  final String? password;

  final void Function(ClientMessage) sendMessage;

  PostgresAuthConnection(this.username, this.password, this.sendMessage);
}

abstract class PostgresAuthenticator {
  static String? name;
  late final PostgresAuthConnection connection;

  PostgresAuthenticator(this.connection);

  void onMessage(AuthenticationMessage message);
}

PostgresAuthenticator createAuthenticator(PostgresAuthConnection connection,
    AuthenticationScheme authenticationScheme) {
  switch (authenticationScheme) {
    case AuthenticationScheme.md5:
      return MD5Authenticator(connection);
    case AuthenticationScheme.scramSha256:
      final credentials = UsernamePasswordCredential(
          username: connection.username, password: connection.password);
      return PostgresSaslAuthenticator(
          connection, ScramAuthenticator('SCRAM-SHA-256', sha256, credentials));
    case AuthenticationScheme.clear:
      return ClearAuthenticator(connection);
  }
}
