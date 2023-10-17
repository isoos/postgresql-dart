import 'package:postgres/legacy.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'docker.dart';

void main() {
  final username = 'abc@def';
  final password = 'pöstgrēs_üšęr_pæsswœêrd';

  withPostgresServer(
    'non-ascii tests (clear password auth)',
    pgUser: username,
    pgPassword: password,
    pgHbaConfContent: _sampleHbaConfigPassword,
    (server) {
      PostgreSQLConnection? conn;
      tearDown(() async {
        await conn?.close();
      });

      test('- Connect with non-ascii connection string', () async {
        conn =
            await server.newPostgreSQLConnection(allowClearTextPassword: true);
        await conn!.open();
        final res = await conn!.query('select 1;');
        expect(res.length, 1);
      });
    },
  );

  withPostgresServer(
    'non-ascii tests (md5 auth)',
    pgUser: username,
    pgPassword: password,
    pgHbaConfContent: _sampleHbaConfigMd5,
    (server) {
      PostgreSQLConnection? conn;
      tearDown(() async {
        await conn?.close();
      });

      test('- Connect with non-ascii connection string', () async {
        conn = await server.newPostgreSQLConnection();
        await conn!.open();
        final res = await conn!.query('select 1;');
        expect(res.length, 1);
      });
    },
  );

  withPostgresServer(
    'non-ascii tests (scram-sha-256 auth)',
    pgUser: username,
    pgPassword: password,
    pgHbaConfContent: _sampleHbaConfigScramSha256,
    (server) {
      PostgreSQLConnection? conn;

      tearDown(() async {
        await conn?.close();
      });

      test('- Connect with non-ascii connection string', () async {
        conn = await server.newPostgreSQLConnection();
        await conn!.open();
        final res = await conn!.query('select 1;');
        expect(res.length, 1);
      });
    },
  );
}

/* -------------------------------------------------------------------------- */
/*                         helper methods and getters                         */
/* -------------------------------------------------------------------------- */

String get _sampleHbaConfigPassword =>
    _sampleHbaContentTrust.replaceAll('trust', 'password');

String get _sampleHbaConfigMd5 =>
    _sampleHbaContentTrust.replaceAll('trust', 'md5');

String get _sampleHbaConfigScramSha256 =>
    _sampleHbaContentTrust.replaceAll('trust', 'scram-sha-256');

/// METHOD can be "trust", "reject", "md5", "password", "scram-sha-256",
/// "gss", "sspi", "ident", "peer", "pam", "ldap", "radius" or "cert".
///
/// Currently, the package only supports: 'md5', 'password', 'scram-sha-256'.
/// See [AuthenticationScheme] within `src/auth/auth.dart`
const _sampleHbaContentTrust = '''
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust 
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust

# when using containers 
host    all             all             0.0.0.0/0               trust
''';
