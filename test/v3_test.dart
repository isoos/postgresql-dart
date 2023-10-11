import 'dart:async';

import 'package:async/async.dart';
import 'package:postgres/messages.dart';
import 'package:postgres/postgres.dart' show PostgreSQLException;
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'docker.dart';

final _sessionSettings = PgSessionSettings(
  // To test SSL, we're running postgres with a self-signed certificate.
  onBadSslCertificate: (cert) => true,

  transformer: loggingTransformer('conn'),
);

void main() {
  withPostgresServer('PgConnection', (server) {
    late PgConnection connection;

    setUp(() async {
      connection = await PgConnection.open(
        await server.endpoint(),
        sessionSettings: _sessionSettings,
      );
    });

    tearDown(() => connection.close());

    test('simple queries', () async {
      expect(await connection.execute("SELECT 'dart', 42, NULL"), [
        ['dart', 42, null]
      ]);
    });

    test('statement without rows', () async {
      final result = await connection.execute(
        PgSql('''SELECT pg_notify('VIRTUAL','Payload 2');'''),
        ignoreRows: true,
      );

      expect(result, isEmpty);
      expect(result.schema.columns, [
        isA<PgResultColumn>()
            .having((e) => e.columnName, 'columnName', 'pg_notify')
            .having((e) => e.type, 'type', PgDataType.voidType)
      ]);
    });

    test('queries without a schema message', () async {
      final response =
          await connection.execute('CREATE TEMPORARY TABLE foo (bar INTEGER);');
      expect(response.affectedRows, isZero);
      expect(response.schema.columns, isEmpty);
    });

    test('can run multiple statements at once', () async {
      await connection.execute('CREATE TEMPORARY TABLE foo (bar INTEGER);');

      final res = await connection.execute(
        'INSERT INTO foo VALUES (1); INSERT INTO foo VALUES (2);',
        // Postgres doesn't allow to prepare multiple statements at once, but
        // we should handle the responses when running simple statements.
        queryMode: QueryMode.simple,
      );
      expect(res.affectedRows, 2);
    });

    group('binary encoding and decoding', () {
      Future<void> shouldPassthrough<T extends Object>(
          PgDataType<T> type, T? value,
          {dynamic matcher}) async {
        final rowFromExplicitType = await connection.execute(
          PgSql(r'SELECT $1', types: [type]),
          parameters: [value],
        );
        expect(rowFromExplicitType, [
          [matcher ?? value]
        ]);

        if (type.nameForSubstitution != null) {
          final rowFromInferredType = await connection.execute(
            PgSql.map('SELECT @var:${type.nameForSubstitution}'),
            parameters: [value],
          );
          expect(rowFromInferredType, [
            [matcher ?? value]
          ]);
        }
      }

      test('string', () async {
        await shouldPassthrough<String>(PgDataType.text, null);
        await shouldPassthrough<String>(PgDataType.text, 'hello world');
      });

      test('int', () async {
        await shouldPassthrough<int>(PgDataType.smallInteger, null);
        await shouldPassthrough<int>(PgDataType.smallInteger, 42);
        await shouldPassthrough<int>(PgDataType.integer, 1024);
        await shouldPassthrough<int>(PgDataType.bigInteger, 999999999999);
      });

      test('real', () async {
        await shouldPassthrough<double>(PgDataType.double, 1.25);
        await shouldPassthrough<double>(PgDataType.double, double.nan,
            matcher: isNaN);
        await shouldPassthrough<double>(
            PgDataType.double, double.negativeInfinity);
      });

      test('numeric', () async {
        await shouldPassthrough<Object>(PgDataType.numeric, 1.25,
            matcher: '1.25');
        await shouldPassthrough<Object>(PgDataType.numeric, 17, matcher: '17');
        await shouldPassthrough<Object>(PgDataType.numeric, double.nan,
            matcher: 'NaN');
      });

      test('regtype', () async {
        await shouldPassthrough<PgDataType>(
            PgDataType.regtype, PgDataType.bigInteger);
      });
    });

    test('listen and notify', () async {
      const channel = 'test_channel';

      expect(connection.channels[channel],
          emitsInOrder(['my notification', isEmpty]));

      await connection.channels.notify(channel, 'my notification');
      await connection.channels.notify(channel);
    });

    test('can use same variable multiple times', () async {
      final stmt = await connection.prepare(
          PgSql(r'SELECT $1 AS a, $1 + 2 AS b', types: [PgDataType.integer]));
      final rows = await stmt.run([10]);

      expect(rows, [
        [10, 12]
      ]);
    });

    test('can use mapped queries with json-contains operator', () async {
      final rows = await connection.execute(
        PgSql.map('SELECT @a:jsonb @> @b:jsonb'),
        parameters: {
          'a': {'foo': 'bar', 'another': 'as well'},
          'b': {'foo': 'bar'},
        },
      );

      expect(rows, [
        [true]
      ]);
    });

    test('can use json path predicate check operator', () async {
      final rows = await connection.execute(
        PgSql.map('SELECT @a:jsonb @@ @b:text::jsonpath'),
        parameters: {
          'a': [1, 2, 3, 4, 5],
          'b': r'$.a[*] > 2',
        },
      );

      expect(rows, [
        [false]
      ]);
    });

    group('throws error', () {
      setUp(() async {
        await connection
            .execute('CREATE TEMPORARY TABLE foo (id INTEGER PRIMARY KEY);');
        await connection.execute('INSERT INTO foo VALUES (1);');
      });

      test('for duplicate with simple query', () async {
        await expectLater(
          () => connection.execute('INSERT INTO foo VALUES (1);'),
          _throwsPostgresException,
        );

        // Make sure the connection is still usable.
        await connection.execute('SELECT 1');
      });

      test('for duplicate with extended query', () async {
        await expectLater(
          () => connection.execute(
            PgSql(r'INSERT INTO foo VALUES ($1);'),
            parameters: [PgTypedParameter(PgDataType.integer, 1)],
          ),
          _throwsPostgresException,
        );

        // Make sure the connection is still in a usable state.
        await connection.execute('SELECT 1');
      });

      test('for duplicate in prepared statement', () async {
        final stmt = await connection.prepare(
          PgSql(r'INSERT INTO foo VALUES ($1);', types: [PgDataType.integer]),
        );
        final stream = stmt.bind([1]);
        await expectLater(stream, emitsError(_isPostgresException));
      });
    });

    test('run', () async {
      const returnValue = 'returned from run()';

      await expectLater(
        connection.run(expectAsync1((session) async {
          expect(identical(connection, session), isTrue);

          await session
              .execute('CREATE TEMPORARY TABLE foo (id INTEGER PRIMARY KEY);');
          await session.execute('INSERT INTO foo VALUES (3);');

          return returnValue;
        })),
        completion(returnValue),
      );

      final rows = await connection.execute('SELECT * FROM foo');
      expect(rows, [
        [3]
      ]);
    });

    group('runTx', () {
      setUp(() async {
        await connection.execute('CREATE TEMPORARY TABLE t (id INT UNIQUE)');
      });

      test('Rows are Lists of column values', () async {
        await connection.execute('INSERT INTO t (id) VALUES (1)');

        final outValue = await connection.runTx((ctx) async {
          return await ctx.execute(
            PgSql(r'SELECT * FROM t WHERE id = $1 LIMIT 1'),
            parameters: [PgTypedParameter(PgDataType.integer, 1)],
          );
        });

        expect(outValue, [
          [1]
        ]);
      });

      test('Send successful transaction succeeds, returns returned value',
          () async {
        final outResult = await connection.runTx((c) async {
          await c.execute('INSERT INTO t (id) VALUES (1)');

          return await c.execute('SELECT id FROM t');
        });
        expect(outResult, [
          [1]
        ]);

        final result = await connection.execute('SELECT id FROM t');
        expect(result, [
          [1]
        ]);
      });

      test('Query during transaction must wait until transaction is finished',
          () async {
        final orderEnsurer = [];
        final nextCompleter = Completer.sync();
        final outResult = connection.runTx((c) async {
          orderEnsurer.add(1);
          await c.execute('INSERT INTO t (id) VALUES (1)');
          orderEnsurer.add(2);
          nextCompleter.complete();
          final result = await c.execute('SELECT id FROM t');
          orderEnsurer.add(3);

          return result;
        });

        await nextCompleter.future;
        orderEnsurer.add(11);
        await connection.execute('INSERT INTO t (id) VALUES (2)');
        orderEnsurer.add(12);
        final laterResults = await connection.execute('SELECT id FROM t');
        orderEnsurer.add(13);

        final firstResult = await outResult;

        expect(orderEnsurer, [1, 2, 11, 3, 12, 13]);
        expect(firstResult, [
          [1]
        ]);
        expect(laterResults, [
          [1],
          [2]
        ]);
      });

      test('Make sure two simultaneous transactions cannot be interwoven',
          () async {
        final orderEnsurer = [];

        final firstTransactionFuture = connection.runTx((c) async {
          orderEnsurer.add(11);
          await c.execute('INSERT INTO t (id) VALUES (1)');
          orderEnsurer.add(12);
          final result = await c.execute('SELECT id FROM t');
          orderEnsurer.add(13);

          return result;
        });

        final secondTransactionFuture = connection.runTx((c) async {
          orderEnsurer.add(21);
          await c.execute('INSERT INTO t (id) VALUES (2)');
          orderEnsurer.add(22);
          final result = await c.execute('SELECT id FROM t');
          orderEnsurer.add(23);

          return result;
        });

        final firstResults = await firstTransactionFuture;
        final secondResults = await secondTransactionFuture;

        expect(orderEnsurer, [11, 12, 13, 21, 22, 23]);

        expect(firstResults, [
          [1]
        ]);
        expect(secondResults, [
          [1],
          [2]
        ]);
      });

      test('A transaction does not preempt pending queries', () async {
        // Add a few insert queries but don't await, then do a transaction that does a fetch,
        // make sure that transaction sees all of the elements.
        unawaited(connection.execute('INSERT INTO t (id) VALUES (1)',
            ignoreRows: true));
        unawaited(connection.execute('INSERT INTO t (id) VALUES (2)',
            ignoreRows: true));
        unawaited(connection.execute('INSERT INTO t (id) VALUES (3)',
            ignoreRows: true));

        final results = await connection.runTx((ctx) async {
          return await ctx.execute('SELECT id FROM t');
        });
        expect(results, [
          [1],
          [2],
          [3]
        ]);
      });

      test('can be rolled back by throwing', () async {
        final expected = Exception('for test');

        await expectLater(
          () => connection.runTx((ctx) async {
            await ctx.execute('INSERT INTO t (id) VALUES (1);');
            throw expected;
          }),
          throwsA(expected),
        );

        expect(await connection.execute('SELECT id FROM t'), isEmpty);
      });

      test('single simple query', () async {
        final res = await connection.execute(
          "SELECT 'dart', 42, true, false, NULL",
          queryMode: QueryMode.simple,
        );
        expect(res, [
          ['dart', 42, true, false, null]
        ]);
      });

      test('parameterized query throws', () async {
        await expectLater(
          () => connection.execute(
            PgSql('SELECT 1'),
            parameters: [PgTypedParameter(PgDataType.integer, 1)],
            queryMode: QueryMode.simple,
          ),
          _throwsPostgresException,
        );
      });
    });

    test('can inject transformer into connection', () async {
      final incoming = <ServerMessage>[];
      final outgoing = <ClientMessage>[];

      final transformer = StreamChannelTransformer<BaseMessage, BaseMessage>(
        StreamTransformer.fromHandlers(
          handleData: (msg, sink) {
            incoming.add(msg as ServerMessage);
            sink.add(msg);
          },
        ),
        StreamSinkTransformer.fromHandlers(handleData: (msg, sink) {
          outgoing.add(msg as ClientMessage);
          sink.add(msg);
        }),
      );

      final connection = await PgConnection.open(
        await server.endpoint(),
        sessionSettings: PgSessionSettings(
          transformer: transformer,
          onBadSslCertificate: (_) => true,
        ),
      );
      addTearDown(connection.close);

      await connection.execute("SELECT 'foo'", ignoreRows: true);
      expect(incoming, contains(isA<DataRowMessage>()));
      expect(outgoing, contains(isA<QueryMessage>()));
    });
  });

  withPostgresServer('can close connection after error conditions', (server) {
    late PgConnection conn1;
    late PgConnection conn2;

    setUp(() async {
      conn1 = await PgConnection.open(
        await server.endpoint(),
        sessionSettings: PgSessionSettings(
          transformer: loggingTransformer('c1'),
          onBadSslCertificate: (cert) => true,
        ),
      );

      conn2 = await PgConnection.open(
        await server.endpoint(),
        sessionSettings: PgSessionSettings(
          transformer: loggingTransformer('c2'),
          onBadSslCertificate: (cert) => true,
        ),
      );
    });

    tearDown(() async {
      await conn1.close();
      await conn2.close();
    });

    for (final concurrentQuery in [false, true]) {
      test(
        'with concurrent query: $concurrentQuery',
        () async {
          final endpoint = await server.endpoint();
          final res = await conn2.execute(
              "SELECT pid FROM pg_stat_activity where usename = '${endpoint.username}';");
          final conn1PID = res.first.first as int;

          // Simulate issue by terminating a connection during a query
          if (concurrentQuery) {
            // We expect that terminating the connection will throw. Use
            // pg_sleep to avoid flaky race conditions between the conditions.
            expect(conn1.execute('select pg_sleep(1) from pg_stat_activity;'),
                _throwsPostgresException);
          }

          // Terminate the conn1 while the query is running
          await conn2.execute('select pg_terminate_backend($conn1PID);');
        },
      );
    }

    test('with simple query protocol', () async {
      final endpoint = await server.endpoint();
      // Get the PID for conn1
      final res = await conn2.execute(
          "SELECT pid FROM pg_stat_activity where usename = '${endpoint.username}';");
      final conn1PID = res.first.first as int;

      expect(
        conn1.execute('select pg_sleep(1) from pg_stat_activity;',
            ignoreRows: true),
        _throwsPostgresException,
      );

      await conn2.execute(
          'select pg_terminate_backend($conn1PID) from pg_stat_activity;');
    });
  });
}

final _isPostgresException = isA<PostgreSQLException>();
final _throwsPostgresException = throwsA(_isPostgresException);
