import 'dart:io';

import 'package:docker_process/containers/postgres.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _kContainerName = 'postgres-dart-test';

void usePostgresDocker() {
  bool isGithubAction() => Platform.environment.containsKey('GITHUB_ACTION');

  setUpAll(() async {
    if (isGithubAction()) {
      // Postgres already running
      return;
    }

    final isRunning = await _isPostgresContainerRunning();
    if (isRunning) {
      return;
    }

    final configPath = p.join(Directory.current.path, 'dev', 'pg_configs');

    final dp = await startPostgres(
      name: _kContainerName,
      version: 'latest',
      pgPort: 5432,
      pgDatabase: 'postgres',
      pgUser: 'postgres',
      pgPassword: 'postgres',
      cleanup: true,
      configurations: [
        // These are necessary for logical replication tests and
        // they won't have an effect on other tests.
        'wal_level=logical',
        'max_replication_slots=5',
        'max_wal_senders=5',
        // SSL settings
        'ssl=on',
        // The debian image includes a self-signed SSL cert that can be used:
        'ssl_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem',
        'ssl_key_file=/etc/ssl/private/ssl-cert-snakeoil.key',
      ],
      pgHbaConfPath: p.join(configPath, 'pg_hba.conf'),
    );

    // Setup the database to support all kind of tests
    // see _setupDatabaseStatements definition for details
    for (var stmt in _setupDatabaseStatements) {
      final args = [
        'psql',
        '-c',
        stmt,
        '-U',
        'postgres',
      ];
      final res = await dp.exec(args);
      if (res.exitCode != 0) {
        final message =
            'Failed to setup PostgreSQL database due to the following error:\n'
            '${res.stderr}';
        throw ProcessException(
          'docker exec $_kContainerName',
          args,
          message,
          res.exitCode,
        );
      }
    }
  });

  tearDownAll(() async {
    if (isGithubAction()) {
      return;
    }
    await Process.run('docker', ['stop', _kContainerName]);
  });
}

Future<bool> _isPostgresContainerRunning() async {
  final pr = await Process.run(
    'docker',
    ['ps', '--format', '{{.Names}}'],
  );
  return pr.stdout
      .toString()
      .split('\n')
      .map((s) => s.trim())
      .contains(_kContainerName);
}


// This setup supports old and new test 
// This is setup is the same as the one from the old travis ci except for the
// replication user which is a new addition. 
final _setupDatabaseStatements = <String>[
  // create testing database
  'create database dart_test;',
  // create dart user
  'create user dart with createdb;',
  "alter user dart with password 'dart';",
  'grant all on database dart_test to dart;',
  // create darttrust user
  'create user darttrust with createdb;',
  'grant all on database dart_test to darttrust;',
  // create replication user
  "create role replication with replication password 'replication' login;",
];
