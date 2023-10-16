import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:docker_process/containers/postgres.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:postgres/legacy.dart';
import 'package:postgres/messages.dart';
import 'package:postgres/postgres.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

// We log all packets sent to and received from the postgres server. This can be
// used to debug failing tests. To view logs, something like this can be put
// at the beginning of `main()`:
//
//  Logger.root.level = Level.ALL;
//  Logger.root.onRecord.listen((r) => print('${r.loggerName}: ${r.message}'));
StreamChannelTransformer<BaseMessage, BaseMessage> loggingTransformer(
    String prefix) {
  final inLogger = Logger('postgres.connection.$prefix.in');
  final outLogger = Logger('postgres.connection.$prefix.out');

  return StreamChannelTransformer(
    StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        inLogger.fine(data);
        sink.add(data);
      },
    ),
    StreamSinkTransformer.fromHandlers(
      handleData: (data, sink) {
        outLogger.fine(data);
        sink.add(data);
      },
    ),
  );
}

class PostgresServer {
  final _port = Completer<int>();
  final _containerName = Completer<String>();

  Future<int> get port => _port.future;
  final bool _useV3;

  PostgresServer({bool? useV3}) : _useV3 = useV3 ?? false;

  bool get useV3 => _useV3;

  /// Can be used as the `skip` parameter on tests that can't run with the v3
  /// backend for v2 API, for instance because they're testing internals.
  String? skippedOnV3([String? reason]) {
    if (_useV3) {
      return reason != null
          ? 'Skipped with v3 delegate: $reason'
          : 'Skipped with v3 delegate.';
    } else {
      return null;
    }
  }

  Future<PgEndpoint> endpoint({
    bool requireSsl = false,
  }) async =>
      PgEndpoint(
        host: 'localhost',
        database: 'postgres',
        username: 'postgres',
        password: 'postgres',
        port: await port,
        requireSsl: requireSsl,
      );

  Future<PgConnection> newConnection({
    bool useSSL = false,
    ReplicationMode replicationMode = ReplicationMode.none,
  }) async {
    return PgConnection.open(
      await endpoint(requireSsl: useSSL),
      sessionSettings: PgSessionSettings(
        replicationMode: replicationMode,
        // We use self-signed certificates in tests
        onBadSslCertificate: (_) => true,
        transformer: loggingTransformer('conn'),
      ),
    );
  }

  Future<PostgreSQLConnection> newPostgreSQLConnection({
    bool useSSL = false,
    ReplicationMode replicationMode = ReplicationMode.none,
  }) async {
    final e = await endpoint();

    if (_useV3) {
      return LegacyPostgreSQLConnection(
        e,
        PgSessionSettings(
          onBadSslCertificate: (_) => true,
          replicationMode: replicationMode,
          allowSuperfluousParameters: true,
        ),
      );
    }

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

@isTestGroup
void withPostgresServer(
  String name,
  void Function(PostgresServer server) fn, {
  Iterable<String>? initSqls,
}) {
  void setupGroup(bool useV3) {
    group(useV3 ? '$name v3' : name, () {
      final server = PostgresServer(useV3: useV3);

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

  if (Platform.environment['V3'] == '1') {
    setupGroup(true);
  } else {
    setupGroup(false);
    setupGroup(true);
  }
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
