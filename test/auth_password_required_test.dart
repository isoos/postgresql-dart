import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

const _username = 'needs_a_password';
const _password = 'sekret';

const _scramSha256HbaConf = '''
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     scram-sha-256
# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-sha-256
# IPv6 local connections:
host    all             all             ::1/128                 scram-sha-256

# when using containers
host    all             all             0.0.0.0/0               scram-sha-256
''';

void main() {
  withPostgresServer(
    'auth requires a password',
    pgUser: _username,
    pgPassword: _password,
    pgHbaConfContent: _scramSha256HbaConf,
    (server) {
      test(
        'connecting without a password fails clearly and promptly',
        () async {
          final endpoint = Endpoint(
            host: 'localhost',
            database: 'postgres',
            username: _username,
            port: await server.port,
          );

          await expectLater(
            Connection.open(
              endpoint,
              settings: ConnectionSettings(sslMode: SslMode.disable),
            ).timeout(Duration(seconds: 10)),
            throwsA(
              isA<PgException>().having(
                (e) => e.message,
                'message',
                contains('no password was provided'),
              ),
            ),
          );
        },
      );
    },
  );
}
