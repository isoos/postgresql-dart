// ignore_for_file: unawaited_futures

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  usePostgresDocker();
  group('connection state', () {
    test('pre-open failure', () async {
      final conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');
      await expectLater(
          () => conn.query('SELECT 1;'),
          throwsA(isA<Exception>().having(
            (e) => '$e',
            'text',
            contains(
                'Attempting to execute query, but connection is not open.'),
          )));
      await conn.open();
      final rs = await conn.query('SELECT 1');
      expect(rs.first.first, 1);
      await conn.close();
    });

    test('pre-open failure with transaction', () async {
      final conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');
      await expectLater(
          () => conn.transaction((_) async {}),
          throwsA(isA<Exception>().having(
            (e) => '$e',
            'text',
            contains(
                'Attempting to execute query, but connection is not open.'),
          )));
      await conn.open();
      await conn.transaction((_) async {});
      await conn.close();
    });

    test('post-close failure', () async {
      final conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');
      await conn.open();
      final rs = await conn.query('SELECT 1');
      expect(rs.first.first, 1);
      await conn.close();
      await expectLater(
          () => conn.query('SELECT 1;'),
          throwsA(isA<Exception>().having(
            (e) => '$e',
            'text',
            contains(
                'Attempting to execute query, but connection is not open.'),
          )));
    });

    test('reopen closed connection', () async {
      final conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');
      await conn.open();
      final rs = await conn.query('SELECT 1');
      expect(rs.first.first, 1);
      await conn.close();
      await expectLater(
          conn.open,
          throwsA(isA<Exception>().having(
            (e) => '$e',
            'text',
            contains(
                'Attempting to reopen a closed connection. Create a instance instead.'),
          )));
    });

    test('Connecting with ReplicationMode.none uses Extended Query Protocol',
        () async {
      final conn = PostgreSQLConnection(
        'localhost',
        5432,
        'dart_test',
        username: 'dart',
        password: 'dart',
        replicationMode: ReplicationMode.none,
      );

      await conn.open();
      // This would throw for ReplicationMode.logical or ReplicationMode.physical
      final result = await conn.query('select 1');
      expect(result.affectedRowCount, equals(1));
    });

    test('Connect with logical ReplicationMode.logical', () async {
      final conn = PostgreSQLConnection(
        'localhost',
        5432,
        'dart_test',
        username: 'replication',
        password: 'replication',
        replicationMode: ReplicationMode.logical,
      );

      await conn.open();

      expect(await conn.execute('select 1'), equals(1));
    });

    test('IDENTIFY_SYSTEM returns system information', () async {
      final conn = PostgreSQLConnection(
        'localhost',
        5432,
        'dart_test',
        username: 'replication',
        password: 'replication',
        replicationMode: ReplicationMode.logical,
      );

      await conn.open();

      // This query can only be executed in Streaming Replication Protocol
      // In addition, it can only be executed using Simple Query Protocol:
      // "In either physical replication or logical replication walsender mode,
      //  only the simple query protocol can be used."
      // source and more info:
      // https://www.postgresql.org/docs/current/protocol-replication.html
      final result = await conn.query(
        'IDENTIFY_SYSTEM;',
        useSimpleQueryProtocol: true,
      );

      expect(result.length, 1);
      expect(result.columnDescriptions.length, 4);
      expect(result.columnDescriptions[0].columnName, 'systemid');
      expect(result.columnDescriptions[1].columnName, 'timeline');
      expect(result.columnDescriptions[2].columnName, 'xlogpos');
      expect(result.columnDescriptions[3].columnName, 'dbname');
    });

    // TODO: add test for ReplicationMode.physical which requires tuning some
    //       settings in the pg_hba.conf
  });

  // These tests are disabled, as we'd need to setup ci/pg_hba.conf into the CI
  // postgres instance first.
  // TODO: re-enable these tests after pg_hba.conf is used
  if (Platform.environment.containsKey('GITHUB_ACTION')) {
    test('NO CONNECTION TEST IS RUNNING.', () {
      // no-op
    });
    return;
  }

  group('Connection lifecycle', () {
    late PostgreSQLConnection conn;

    tearDown(() async {
      await conn.close();
    });

    test('Connect with md5 or scram-sha-256 auth required', () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');

      await conn.open();

      expect(await conn.execute('select 1'), equals(1));
    });

    test('SSL Connect with md5 or scram-sha-256 auth required', () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart', useSSL: true);

      await conn.open();

      expect(await conn.execute('select 1'), equals(1));
      final socketMirror = reflect(conn).type.declarations.values.firstWhere(
          (DeclarationMirror dm) =>
              dm.simpleName.toString().contains('_socket'));
      final underlyingSocket =
          reflect(conn).getField(socketMirror.simpleName).reflectee;
      expect(underlyingSocket is SecureSocket, true);
    });

    test('Connect with no auth required', () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust');
      await conn.open();

      expect(await conn.execute('select 1'), equals(1));
    });

    test('SSL Connect with no auth required', () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust', useSSL: true);
      await conn.open();

      expect(await conn.execute('select 1'), equals(1));
    });

    test('Closing idle connection succeeds, closes underlying socket',
        () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust');
      await conn.open();

      await conn.close();

      final socketMirror = reflect(conn).type.declarations.values.firstWhere(
          (DeclarationMirror dm) =>
              dm.simpleName.toString().contains('_socket'));
      final underlyingSocket =
          reflect(conn).getField(socketMirror.simpleName).reflectee as Socket;
      expect(await underlyingSocket.done, isNotNull);
    });

    test('SSL Closing idle connection succeeds, closes underlying socket',
        () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust', useSSL: true);
      await conn.open();

      await conn.close();

      final socketMirror = reflect(conn).type.declarations.values.firstWhere(
          (DeclarationMirror dm) =>
              dm.simpleName.toString().contains('_socket'));
      final underlyingSocket =
          reflect(conn).getField(socketMirror.simpleName).reflectee as Socket;
      expect(await underlyingSocket.done, isNotNull);
    });

    test(
        'Closing connection while busy succeeds, queued queries are all accounted for (canceled), closes underlying socket',
        () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust');
      await conn.open();

      final rs = await conn.query('select 1');
      final errors = [];
      final catcher = (e) {
        errors.add(e);
        return rs;
      };
      final futures = [
        conn.query('select 1', allowReuse: false).catchError(catcher),
        conn.query('select 2', allowReuse: false).catchError(catcher),
        conn.query('select 3', allowReuse: false).catchError(catcher),
        conn.query('select 4', allowReuse: false).catchError(catcher),
        conn.query('select 5', allowReuse: false).catchError(catcher),
      ];

      await conn.close();
      await Future.wait(futures);
      expect(errors.length, 5);
      expect(errors.map((e) => e.message),
          everyElement(contains('Query cancelled')));
    });

    test(
        'SSL Closing connection while busy succeeds, queued queries are all accounted for (canceled), closes underlying socket',
        () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust', useSSL: true);
      await conn.open();
      final rs = await conn.query('select 1');

      final errors = [];
      final catcher = (e) {
        errors.add(e);
        return rs;
      };
      final futures = [
        conn.query('select 1', allowReuse: false).catchError(catcher),
        conn.query('select 2', allowReuse: false).catchError(catcher),
        conn.query('select 3', allowReuse: false).catchError(catcher),
        conn.query('select 4', allowReuse: false).catchError(catcher),
        conn.query('select 5', allowReuse: false).catchError(catcher),
      ];

      await conn.close();
      await Future.wait(futures);
      expect(errors.length, 5);
      expect(errors.map((e) => e.message),
          everyElement(contains('Query cancelled')));
    });
  });

  group('Successful queries over time', () {
    late PostgreSQLConnection conn;

    setUp(() async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust');
      await conn.open();
    });

    tearDown(() async {
      await conn.close();
    });

    test(
        'Issuing multiple queries and awaiting between each one successfully returns the right value',
        () async {
      expect(
          await conn.query('select 1', allowReuse: false),
          equals([
            [1]
          ]));
      expect(
          await conn.query('select 2', allowReuse: false),
          equals([
            [2]
          ]));
      expect(
          await conn.query('select 3', allowReuse: false),
          equals([
            [3]
          ]));
      expect(
          await conn.query('select 4', allowReuse: false),
          equals([
            [4]
          ]));
      expect(
          await conn.query('select 5', allowReuse: false),
          equals([
            [5]
          ]));
    });

    test(
        'Issuing multiple queries without awaiting are returned with appropriate values',
        () async {
      final futures = [
        conn.query('select 1', allowReuse: false),
        conn.query('select 2', allowReuse: false),
        conn.query('select 3', allowReuse: false),
        conn.query('select 4', allowReuse: false),
        conn.query('select 5', allowReuse: false)
      ];

      final results = await Future.wait(futures);

      expect(results, [
        [
          [1]
        ],
        [
          [2]
        ],
        [
          [3]
        ],
        [
          [4]
        ],
        [
          [5]
        ]
      ]);
    });
  });

  group('Unintended user-error situations', () {
    late PostgreSQLConnection conn;
    Future? openFuture;

    tearDown(() async {
      await openFuture;
      await conn.close();
    });

    test('Sending queries to opening connection triggers error', () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust');
      openFuture = conn.open();

      try {
        await conn.execute('select 1');
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.message, contains('connection is not open'));
      }
    });

    test('SSL Sending queries to opening connection triggers error', () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust', useSSL: true);
      openFuture = conn.open();

      try {
        await conn.execute('select 1');
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.message, contains('connection is not open'));
      }
    });

    test('Starting transaction while opening connection triggers error',
        () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust');
      openFuture = conn.open();

      try {
        await conn.transaction((ctx) async {
          await ctx.execute('select 1');
        });
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.message, contains('connection is not open'));
      }
    });

    test('SSL Starting transaction while opening connection triggers error',
        () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust', useSSL: true);
      openFuture = conn.open();

      try {
        await conn.transaction((ctx) async {
          await ctx.execute('select 1');
        });
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.message, contains('connection is not open'));
      }
    });

    test('Invalid password reports error, conn is closed, disables conn',
        () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'notdart');

      try {
        await conn.open();
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.message, contains('password authentication failed'));
      }

      await expectConnectionIsInvalid(conn);
    });

    test('SSL Invalid password reports error, conn is closed, disables conn',
        () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'notdart', useSSL: true);

      try {
        await conn.open();
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.message, contains('password authentication failed'));
      }

      await expectConnectionIsInvalid(conn);
    });

    test('A query error maintains connectivity, allows future queries',
        () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust');
      await conn.open();

      await conn.execute('CREATE TEMPORARY TABLE t (i int unique)');
      await conn.execute('INSERT INTO t (i) VALUES (1)');
      try {
        await conn.execute('INSERT INTO t (i) VALUES (1)');
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.message, contains('duplicate key value violates'));
      }

      await conn.execute('INSERT INTO t (i) VALUES (2)');
    });

    test(
        'A query error maintains connectivity, continues processing pending queries',
        () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust');
      await conn.open();

      await conn.execute('CREATE TEMPORARY TABLE t (i int unique)');

      await conn.execute('INSERT INTO t (i) VALUES (1)');

      conn.execute('INSERT INTO t (i) VALUES (1)').catchError((e) {
        // ignore
        return 0;
      });

      final futures = [
        conn.query('select 1', allowReuse: false),
        conn.query('select 2', allowReuse: false),
        conn.query('select 3', allowReuse: false),
      ];
      final results = await Future.wait(futures);

      expect(results, [
        [
          [1]
        ],
        [
          [2]
        ],
        [
          [3]
        ]
      ]);

      final queueMirror = reflect(conn).type.instanceMembers.values.firstWhere(
          (DeclarationMirror dm) =>
              dm.simpleName.toString().contains('_queue'));
      final queue =
          reflect(conn).getField(queueMirror.simpleName).reflectee as List;
      expect(queue, isEmpty);
    });

    test(
        'A query error maintains connectivity, continues processing pending transactions',
        () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust');
      await conn.open();

      await conn.execute('CREATE TEMPORARY TABLE t (i int unique)');
      await conn.execute('INSERT INTO t (i) VALUES (1)');

      final orderEnsurer = [];

      // this will emit a query error
      conn.execute('INSERT INTO t (i) VALUES (1)').catchError((err) {
        orderEnsurer.add(1);
        // ignore
        return 0;
      });

      orderEnsurer.add(2);
      final res = await conn.transaction((ctx) async {
        orderEnsurer.add(3);
        return await ctx.query('SELECT i FROM t');
      });
      orderEnsurer.add(4);

      expect(res, [
        [1]
      ]);
      expect(orderEnsurer, [2, 1, 3, 4]);
    });

    test(
        'Building query throws error, connection continues processing pending queries',
        () async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'darttrust');
      await conn.open();

      // Make some async queries that'll exit the event loop, but then fail on a query that'll die early
      conn.execute('askdl').catchError((err, st) => 0);
      conn.execute('abdef').catchError((err, st) => 0);
      conn.execute('select @a').catchError((err, st) => 0);

      final futures = [
        conn.query('select 1', allowReuse: false),
        conn.query('select 2', allowReuse: false),
      ];
      final results = await Future.wait(futures);

      expect(results, [
        [
          [1]
        ],
        [
          [2]
        ]
      ]);

      final queueMirror = reflect(conn).type.instanceMembers.values.firstWhere(
          (DeclarationMirror dm) =>
              dm.simpleName.toString().contains('_queue'));
      final queue =
          reflect(conn).getField(queueMirror.simpleName).reflectee as List;
      expect(queue, isEmpty);
    });
  });

  group('Network error situations', () {
    ServerSocket? serverSocket;
    Socket? socket;

    tearDown(() async {
      if (serverSocket != null) {
        await serverSocket!.close();
      }
      if (socket != null) {
        await socket!.close();
      }
    });

    test(
        'Socket fails to connect reports error, disables connection for future use',
        () async {
      final conn = PostgreSQLConnection('localhost', 5431, 'dart_test');

      try {
        await conn.open();
        expect(true, false);
      } on SocketException {
        // ignore
      }

      await expectConnectionIsInvalid(conn);
    });

    test(
        'SSL Socket fails to connect reports error, disables connection for future use',
        () async {
      final conn =
          PostgreSQLConnection('localhost', 5431, 'dart_test', useSSL: true);

      try {
        await conn.open();
        expect(true, false);
      } on SocketException {
        // ignore
      }

      await expectConnectionIsInvalid(conn);
    });

    test(
        'Connection that times out throws appropriate error and cannot be reused',
        () async {
      serverSocket =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, 5433);
      serverSocket!.listen((s) {
        socket = s;
        // Don't respond on purpose
        s.listen((bytes) {});
      });

      final conn = PostgreSQLConnection('localhost', 5433, 'dart_test',
          timeoutInSeconds: 2);

      try {
        await conn.open();
        fail('unreachable');
      } on TimeoutException {
        // ignore
      }

      await expectConnectionIsInvalid(conn);
    });

    test(
        'SSL Connection that times out throws appropriate error and cannot be reused',
        () async {
      serverSocket =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, 5433);
      serverSocket!.listen((s) {
        socket = s;
        // Don't respond on purpose
        s.listen((bytes) {});
      });

      final conn = PostgreSQLConnection('localhost', 5433, 'dart_test',
          timeoutInSeconds: 2, useSSL: true);

      try {
        await conn.open();
        fail('unreachable');
      } on TimeoutException {
        // ignore
      }

      await expectConnectionIsInvalid(conn);
    });

    test('Connection that times out triggers future for pending queries',
        () async {
      final openCompleter = Completer();
      serverSocket =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, 5433);
      serverSocket!.listen((s) {
        socket = s;
        // Don't respond on purpose
        s.listen((bytes) {});
        Future.delayed(Duration(milliseconds: 100), openCompleter.complete);
      });

      final conn = PostgreSQLConnection('localhost', 5433, 'dart_test',
          timeoutInSeconds: 2);
      conn.open().catchError((e) {});

      await openCompleter.future;

      try {
        await conn.execute('select 1');
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.message, contains('Failed to connect'));
      }
    });

    test('SSL Connection that times out triggers future for pending queries',
        () async {
      final openCompleter = Completer();
      serverSocket =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, 5433);
      serverSocket!.listen((s) {
        socket = s;
        // Don't respond on purpose
        s.listen((bytes) {});
        Future.delayed(Duration(milliseconds: 100), openCompleter.complete);
      });

      final conn = PostgreSQLConnection('localhost', 5433, 'dart_test',
          timeoutInSeconds: 2, useSSL: true);
      conn.open().catchError((e) {
        return null;
      });

      await openCompleter.future;

      try {
        await conn.execute('select 1');
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.message, contains('but connection is not open'));
      }

      try {
        await conn.open();
        expect(true, false);
      } on PostgreSQLException {
        // ignore
      }
    });
  });

  test('If connection is closed, do not allow .execute', () async {
    final conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
        username: 'dart', password: 'dart');
    try {
      await conn.execute('SELECT 1');
      fail('unreachable');
    } on PostgreSQLException catch (e) {
      expect(e.toString(), contains('connection is not open'));
    }
  });

  test('If connection is closed, do not allow .query', () async {
    final conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
        username: 'dart', password: 'dart');
    try {
      await conn.query('SELECT 1');
      fail('unreachable');
    } on PostgreSQLException catch (e) {
      expect(e.toString(), contains('connection is not open'));
    }
  });

  test('If connection is closed, do not allow .mappedResultsQuery', () async {
    final conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
        username: 'dart', password: 'dart');
    try {
      await conn.mappedResultsQuery('SELECT 1');
      fail('unreachable');
    } on PostgreSQLException catch (e) {
      expect(e.toString(), contains('connection is not open'));
    }
  });

  test(
      'Queue size, should be 0 on open, >0 if queries added and 0 again after queries executed',
      () async {
    final conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
        username: 'dart', password: 'dart');
    await conn.open();
    expect(conn.queueSize, 0);

    final futures = [
      conn.query('select 1', allowReuse: false),
      conn.query('select 2', allowReuse: false),
      conn.query('select 3', allowReuse: false)
    ];
    expect(conn.queueSize, 3);

    await Future.wait(futures);
    expect(conn.queueSize, 0);
  });
}

Future expectConnectionIsInvalid(PostgreSQLConnection conn) async {
  try {
    await conn.execute('select 1');
    expect(true, false);
  } on PostgreSQLException catch (e) {
    expect(e.message, contains('connection is not open'));
  }

  try {
    await conn.open();
    expect(true, false);
  } on PostgreSQLException catch (e) {
    expect(e.message, contains('Attempting to reopen a closed connection'));
  }
}
