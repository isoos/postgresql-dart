import 'dart:async';

import 'package:async/async.dart';
import 'package:postgres/messages.dart';
import 'package:postgres/postgres.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'docker.dart';

final _sessionSettings = SessionSettings(
  transformer: loggingTransformer('conn'),
  applicationName: 'test_app',
);

void main() {
  withPostgresServer('PgConnection', (server) {
    late Connection connection;

    setUp(() async {
      connection = await Connection.open(
        await server.endpoint(),
        sessionSettings: _sessionSettings,
      );
    });

    tearDown(() => connection.close());

    test('simple queries', () async {
      final rs = await connection.execute("SELECT 'dart', 42, NULL");
      expect(rs, [
        ['dart', 42, null]
      ]);
      expect(rs.single.toColumnMap(), {'?column?': null});

      final appRs = await connection
          .execute("SELECT current_setting('application_name');");
      expect(appRs.single.single, 'test_app');
    });

    test('statement without rows', () async {
      final result = await connection.execute(
        Sql('''SELECT pg_notify('VIRTUAL','Payload 2');'''),
        ignoreRows: true,
      );

      expect(result, isEmpty);
      expect(result.schema.columns, [
        isA<ResultSchemaColumn>()
            .having((e) => e.columnName, 'columnName', 'pg_notify')
            .having((e) => e.type, 'type', Type.voidType)
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

    test('queue multiple queries concurrently, execute sequentially', () async {
      final sw = Stopwatch()..start();
      await Future.wait([
        connection.execute('SELECT 1, pg_sleep(1)'),
        connection.execute('SELECT 1, pg_sleep(2)'),
        connection.execute('SELECT 1, pg_sleep(3)'),
      ]);
      expect(sw.elapsed.inSeconds >= 6, isTrue);
    });

    group('binary encoding and decoding', () {
      Future<void> shouldPassthrough<T extends Object>(Type<T> type, T? value,
          {dynamic matcher}) async {
        final rowFromExplicitType = await connection.execute(
          Sql(r'SELECT $1', types: [type]),
          parameters: [value],
        );
        expect(rowFromExplicitType, [
          [matcher ?? value]
        ]);

        if (type.nameForSubstitution != null) {
          final rowFromInferredType = await connection.execute(
            Sql.named('SELECT @var:${type.nameForSubstitution}'),
            parameters: [value],
          );
          expect(rowFromInferredType, [
            [matcher ?? value]
          ]);
        }
      }

      test('string', () async {
        await shouldPassthrough<String>(Type.text, null);
        await shouldPassthrough<String>(Type.text, 'hello world');
      });

      test('int', () async {
        await shouldPassthrough<int>(Type.smallInteger, null);
        await shouldPassthrough<int>(Type.smallInteger, 42);
        await shouldPassthrough<int>(Type.integer, 1024);
        await shouldPassthrough<int>(Type.bigInteger, 999999999999);
      });

      test('real', () async {
        await shouldPassthrough<double>(Type.double, 1.25);
        await shouldPassthrough<double>(Type.double, double.nan,
            matcher: isNaN);
        await shouldPassthrough<double>(Type.double, double.negativeInfinity);
      });

      test('numeric', () async {
        await shouldPassthrough<Object>(Type.numeric, 1.25, matcher: '1.25');
        await shouldPassthrough<Object>(Type.numeric, 17, matcher: '17');
        await shouldPassthrough<Object>(Type.numeric, double.nan,
            matcher: 'NaN');
      });

      test('regtype', () async {
        await shouldPassthrough<Type>(Type.regtype, Type.bigInteger);
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
      final stmt = await connection
          .prepare(Sql(r'SELECT $1 AS a, $1 + 2 AS b', types: [Type.integer]));
      final rows = await stmt.run([10]);

      expect(rows, [
        [10, 12]
      ]);
      expect(rows.single.toColumnMap(), {'a': 10, 'b': 12});
    });

    test('can use mapped queries with json-contains operator', () async {
      final rows = await connection.execute(
        Sql.named('SELECT @a:jsonb @> @b:jsonb'),
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
        Sql.named('SELECT @a:jsonb @@ @b:text::jsonpath'),
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
            Sql(r'INSERT INTO foo VALUES ($1);'),
            parameters: [TypedValue(Type.integer, 1)],
          ),
          _throwsPostgresException,
        );

        // Make sure the connection is still in a usable state.
        await connection.execute('SELECT 1');
      });

      test('for duplicate in prepared statement', () async {
        final stmt = await connection.prepare(
          Sql(r'INSERT INTO foo VALUES ($1);', types: [Type.integer]),
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
            Sql(r'SELECT * FROM t WHERE id = $1 LIMIT 1'),
            parameters: [TypedValue(Type.integer, 1)],
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
            Sql('SELECT 1'),
            parameters: [TypedValue(Type.integer, 1)],
            queryMode: QueryMode.simple,
          ),
          _throwsPostgresException,
        );
      });
    });

    test('can inject transformer into connection', () async {
      final incoming = <ServerMessage>[];
      final outgoing = <ClientMessage>[];

      final transformer = StreamChannelTransformer<Message, Message>(
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

      final connection = await Connection.open(
        await server.endpoint(),
        sessionSettings: SessionSettings(
          transformer: transformer,
        ),
      );
      addTearDown(connection.close);

      await connection.execute("SELECT 'foo'", ignoreRows: true);
      expect(incoming, contains(isA<DataRowMessage>()));
      expect(outgoing, contains(isA<QueryMessage>()));
    });
  });

  withPostgresServer('can close connection after error conditions', (server) {
    late Connection conn1;
    late Connection conn2;

    setUp(() async {
      conn1 = await Connection.open(
        await server.endpoint(),
        sessionSettings: SessionSettings(
          transformer: loggingTransformer('c1'),
        ),
      );

      conn2 = await Connection.open(
        await server.endpoint(),
        sessionSettings: SessionSettings(
          transformer: loggingTransformer('c2'),
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

final _isPostgresException = isA<PgException>();
final _throwsPostgresException = throwsA(_isPostgresException);
