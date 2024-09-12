import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:docker_process/containers/postgres.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:postgres/messages.dart';
import 'package:postgres/postgres.dart';
import 'package:postgres/src/v3/connection.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

final _splitAndDelayBytes = false;

// We log all packets sent to and received from the postgres server. This can be
// used to debug failing tests. To view logs, something like this can be put
// at the beginning of `main()`:
//
//  Logger.root.level = Level.ALL;
//  Logger.root.onRecord.listen((r) => print('${r.loggerName}: ${r.message}'));
StreamChannelTransformer<Message, Message> loggingTransformer(String prefix) {
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
  final String? _pgUser;
  final String? _pgPassword;

  PostgresServer({
    String? pgUser,
    String? pgPassword,
  })  : _pgUser = pgUser,
        _pgPassword = pgPassword;

  Future<Endpoint> endpoint() async => Endpoint(
        host: 'localhost',
        database: 'postgres',
        username: _pgUser ?? 'postgres',
        password: _pgPassword ?? 'postgres',
        port: await port,
      );

  Future<Connection> newConnection({
    ReplicationMode replicationMode = ReplicationMode.none,
    SslMode? sslMode,
    QueryMode? queryMode,
  }) async {
    return await PgConnectionImplementation.connect(
      await endpoint(),
      connectionSettings: ConnectionSettings(
        connectTimeout: Duration(seconds: 3),
        queryTimeout: Duration(seconds: 3),
        replicationMode: replicationMode,
        transformer: loggingTransformer('conn'),
        sslMode: sslMode,
        queryMode: queryMode,
      ),
      incomingBytesTransformer:
          _splitAndDelayBytes ? _transformIncomingBytes() : null,
    );
  }

  Future<void> kill() async {
    await Process.run('docker', ['kill', await _containerName.future]);
  }
}

StreamTransformer<Uint8List, Uint8List> _transformIncomingBytes() {
  return StreamTransformer.fromBind((s) => s.asyncExpand((u) {
        if (u.length <= 2) {
          return Stream.value(u);
        }
        final hash = u.hashCode.abs();
        final split = hash % u.length;
        if (split == 0 || split >= u.length - 1) {
          return Stream.value(u);
        }

        final p1 = u.sublist(0, split);
        final p2 = u.sublist(split);

        return Stream.fromFutures([
          Future.value(p1),
          Future.delayed(
            Duration(milliseconds: 50),
            () => p2,
          )
        ]);
      }));
}

@isTestGroup
void withPostgresServer(
  String name,
  void Function(PostgresServer server) fn, {
  Iterable<String>? initSqls,
  String? pgUser,
  String? pgPassword,
  String? pgHbaConfContent,
  String? timeZone,
}) {
  group(name, () {
    final server = PostgresServer(
      pgUser: pgUser,
      pgPassword: pgPassword,
    );
    Directory? tempDir;

    setUpAll(() async {
      try {
        final port = await selectFreePort();
        String? pgHbaConfPath;
        if (pgHbaConfContent != null) {
          tempDir =
              await Directory.systemTemp.createTemp('postgres-dart-test-$port');
          pgHbaConfPath = p.join(tempDir!.path, 'pg_hba.conf');
          await File(pgHbaConfPath).writeAsString(pgHbaConfContent);
        }

        final containerName = 'postgres-dart-test-$port';
        await _startPostgresContainer(
          port: port,
          containerName: containerName,
          initSqls: initSqls ?? const <String>[],
          pgUser: pgUser,
          pgPassword: pgPassword,
          pgHbaConfPath: pgHbaConfPath,
          timeZone: timeZone,
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
      await tempDir?.delete(recursive: true);
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
  String? pgUser,
  String? pgPassword,
  String? pgHbaConfPath,
  String? timeZone,
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
    pgUser: pgUser ?? 'postgres',
    pgPassword: pgPassword ?? 'postgres',
    cleanup: true,
    configurations: [
      // SSL settings
      'ssl=on',
      // The debian image includes a self-signed SSL cert that can be used:
      'ssl_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem',
      'ssl_key_file=/etc/ssl/private/ssl-cert-snakeoil.key',
    ],
    pgHbaConfPath: pgHbaConfPath ?? p.join(configPath, 'pg_hba.conf'),
    postgresqlConfPath: p.join(configPath, 'postgresql.conf'),
    timeZone: timeZone,
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
