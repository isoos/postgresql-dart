import 'dart:io';

import 'package:docker_process/containers/postgres.dart';
import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  final user = 'abc@def';
  final password = 'pöstgrēs_üšęr_pæsswœêrd';
  final db = 'postgres';

  group('non-ascii tests (clear password auth)', () {
    late final DockerProcess docker;
    final port = 54321;

    setUpAll(
      () async {
        docker = await startPostgres(
          name: 'non_ascii_test_clear_password',
          version: 'latest',
          pgPort: port,
          pgDatabase: db,
          pgUser: user,
          pgPassword: password,
          cleanup: true,
          pgHbaConfPath: _createTempFile(
            fileName: 'pg_hba.conf',
            contents: _sampleHbaConfigPassword,
          ),
        );
      },
    );

    tearDownAll(() {
      docker.stop();
      docker.kill();
    });
    PostgreSQLConnection? conn;

    setUp(() async {
      conn = PostgreSQLConnection('localhost', port, db,
          username: user, password: password, allowClearTextPassword: true);
      await conn!.open();
    });

    tearDown(() async {
      await conn?.close();
    });

    test('- Connect with non-ascii connection string', () async {
      final res = await conn!.query('select 1;');
      expect(res.length, 1);
    });
  });

  group('non-ascii tests (md5 auth)', () {
    late final DockerProcess docker;
    final port = 54322;
    setUpAll(
      () async {
        docker = await startPostgres(
          name: 'non_ascii_test_md5',
          version: 'latest',
          pgPort: port,
          pgDatabase: db,
          pgUser: user,
          pgPassword: password,
          cleanup: true,
          pgHbaConfPath: _createTempFile(
            fileName: 'pg_hba.conf',
            contents: _sampleHbaConfigMd5,
          ),
        );
      },
    );

    tearDownAll(() {
      docker.stop();
      docker.kill();
    });
    PostgreSQLConnection? conn;

    setUp(() async {
      conn = PostgreSQLConnection(
        'localhost',
        port,
        db,
        username: user,
        password: password,
      );
      await conn!.open();
    });

    tearDown(() async {
      await conn?.close();
    });

    test('- Connect with non-ascii connection string', () async {
      final res = await conn!.query('select 1;');
      expect(res.length, 1);
    });
  });

  group('non-ascii tests (scram-sha-256 auth)', () {
    late final DockerProcess docker;
    final port = 54323;
    setUpAll(
      () async {
        docker = await startPostgres(
          name: 'non_ascii_test_scram_sha256',
          version: 'latest',
          pgPort: port,
          pgDatabase: db,
          pgUser: user,
          pgPassword: password,
          cleanup: true,
          pgHbaConfPath: _createTempFile(
            fileName: 'pg_hba.conf',
            contents: _sampleHbaConfigScramSha256,
          ),
        );
      },
    );

    tearDownAll(() {
      docker.stop();
      docker.kill();
    });
    PostgreSQLConnection? conn;

    setUp(() async {
      conn = PostgreSQLConnection(
        'localhost',
        port,
        db,
        username: user,
        password: password,
      );
      await conn!.open();
    });

    tearDown(() async {
      await conn?.close();
    });

    test('- Connect with non-ascii connection string', () async {
      final res = await conn!.query('select 1;');
      expect(res.length, 1);
    });
  });
}

/* -------------------------------------------------------------------------- */
/*                         helper methods and getters                         */
/* -------------------------------------------------------------------------- */

String _createTempFile({
  required String fileName,
  required String contents,
}) {
  final file = File(p.join(
    Directory.systemTemp.path,
    DateTime.now().millisecondsSinceEpoch.toString(),
    fileName,
  ));

  file.createSync(recursive: true);
  file.writeAsStringSync(contents);
  return file.path;
}

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
