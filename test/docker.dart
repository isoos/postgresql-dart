import 'dart:async';
import 'dart:io';

import 'package:docker_process/containers/postgres.dart';
import 'package:path/path.dart' as p;
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:postgres/src/connection.dart';
import 'package:postgres/src/replication.dart';
import 'package:test/test.dart';

class PostgresServer {
  final _port = Completer<int>();
  final _containerName = Completer<String>();

  Future<int> get port => _port.future;

  Future<PgEndpoint> get endpoint async => PgEndpoint(
        host: 'localhost',
        database: 'postgres',
        username: 'postgres',
        password: 'postgres',
        port: await port,
      );

  Future<PostgreSQLConnection> newPostgreSQLConnection({
    bool useSSL = false,
    ReplicationMode replicationMode = ReplicationMode.none,
  }) async {
    final e = await endpoint;
    return PostgreSQLConnection(
      e.host,
      e.port,
      e.database,
      username: e.username,
      password: e.password,
      useSSL: useSSL,
      replicationMode: replicationMode,
    );
  }
}

void withPostgresServer(
  String name,
  void Function(PostgresServer server) fn, {
  Iterable<String>? initSqls,
}) {
  group(name, () {
    final server = PostgresServer();

    setUpAll(() async {
      try {
        final port = await selectFreePort();

        final containerName = 'postgres-dart-test-$port';
        await _startPostgresContainer(
          port: port,
          containerName: containerName,
          initSqls: initSqls ?? const <String>[],
        );

        server._containerName.complete(containerName);
        server._port.complete(port);
      } catch (e, st) {
        server._containerName.completeError(e, st);
        server._port.completeError(e, st);
        rethrow;
      }
    });

    tearDownAll(() async {
      final containerName = await server._containerName.future;
      await Process.run('docker', ['stop', containerName]);
      await Process.run('docker', ['kill', containerName]);
    });

    fn(server);
  });
}

Future<int> selectFreePort() async {
  final socket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<void> _startPostgresContainer({
  required int port,
  required String containerName,
  required Iterable<String> initSqls,
}) async {
  final isRunning = await _isPostgresContainerRunning(containerName);
  if (isRunning) {
    return;
  }

  final configPath = p.join(Directory.current.path, 'test', 'pg_configs');

  final dp = await startPostgres(
    name: containerName,
    version: 'latest',
    pgPort: port,
    pgDatabase: 'postgres',
    pgUser: 'postgres',
    pgPassword: 'postgres',
    cleanup: true,
    configurations: [
      // SSL settings
      'ssl=on',
      // The debian image includes a self-signed SSL cert that can be used:
      'ssl_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem',
      'ssl_key_file=/etc/ssl/private/ssl-cert-snakeoil.key',
    ],
    pgHbaConfPath: p.join(configPath, 'pg_hba.conf'),
    postgresqlConfPath: p.join(configPath, 'postgresql.conf'),
  );

  // Setup the database to support all kind of tests
  for (final stmt in initSqls) {
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
        'docker exec $containerName',
        args,
        message,
        res.exitCode,
      );
    }
  }
}

Future<bool> _isPostgresContainerRunning(String containerName) async {
  final pr = await Process.run(
    'docker',
    ['ps', '--format', '{{.Names}}'],
  );
  return pr.stdout
      .toString()
      .split('\n')
      .map((s) => s.trim())
      .contains(containerName);
}

/// This is setup is the same as the one from the old travis ci.
const oldSchemaInit = <String>[
  // create testing database
  'create database dart_test;',
  // create dart user
  'create user dart with createdb;',
  "alter user dart with password 'dart';",
  'grant all on database dart_test to dart;',
  // create darttrust user
  'create user darttrust with createdb;',
  'grant all on database dart_test to darttrust;',
];

const replicationSchemaInit = <String>[
  // create replication user
  "create role replication with replication password 'replication' login;",
];
