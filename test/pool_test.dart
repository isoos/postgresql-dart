import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('generic', (server) {
    late Pool pool;

    setUp(() async {
      pool = Pool.withEndpoints(
        [await server.endpoint()],
        settings: PoolSettings(maxConnectionCount: 8),
      );

      // We can't write to the public schema by default in postgres 15, so
      // create one for this test.
      await pool.execute('CREATE SCHEMA IF NOT EXISTS test');
    });
    tearDown(() => pool.close());

    test('does not support channels', () {
      expect(pool.withConnection((c) async => c.channels.notify('foo')),
          throwsUnsupportedError);
    });

    test('execute re-uses free connection', () async {
      // The temporary table is only visible to the connection creating it, so
      // this asserts that all statements are running on the same underlying
      // connection.
      await pool.execute('CREATE TEMPORARY TABLE foo (bar INTEGER);');

      await pool.execute('INSERT INTO foo VALUES (1), (2), (3);');
      final results = await pool.execute('SELECT * FROM foo');
      expect(results, hasLength(3));
    });

    test('can use transactions', () async {
      // The table can't be temporary because it needs to be visible across
      // connections.
      await pool.execute(
          'CREATE TABLE IF NOT EXISTS test.transactions (bar INTEGER);');
      addTearDown(() => pool.execute('DROP TABLE test.transactions;'));

      final completeTransaction = Completer();
      final transaction = pool.runTx((session) async {
        await session
            .execute('INSERT INTO test.transactions VALUES (1), (2), (3);');
        await completeTransaction.future;
      });

      var rows = await pool.execute('SELECT * FROM test.transactions');
      expect(rows, isEmpty);

      completeTransaction.complete();
      await transaction;

      rows = await pool.execute('SELECT * FROM test.transactions');
      expect(rows, hasLength(3));
    });

    test('can use prepared statements', () async {
      await pool
          .execute('CREATE TABLE IF NOT EXISTS test.statements (bar INTEGER);');
      addTearDown(() => pool.execute('DROP TABLE test.statements;'));

      final stmt = await pool.prepare('SELECT * FROM test.statements');
      expect(await stmt.run([]), isEmpty);

      await pool.execute('INSERT INTO test.statements VALUES (1), (2), (3);');

      expect(await stmt.run([]), hasLength(3));
      await stmt.dispose();
    });

    test('disables close()', () async {
      late Connection leakedConnection;

      await pool.withConnection((connection) async {
        expect(connection.isOpen, isTrue);
        await connection.close();
        expect(connection.isOpen, isTrue);

        leakedConnection = connection;
      });

      await pool.close();
      expect(pool.isOpen, isFalse);
      expect(leakedConnection.isOpen, isFalse);
    });
  });

  withPostgresServer('handles session errors', (server) {
    test('timeout unlocks pool', () async {
      final db = Pool.withEndpoints(
        [await server.endpoint()],
        settings: PoolSettings(
          maxConnectionCount: 1,
          connectTimeout: Duration(seconds: 3),
        ),
      );

      await expectLater(
        () => db.run((_) async {
          // NOTE: session is not used here
          await db.execute('SELECT 1');
        }),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('bad query does not lock up pool instance', () async {
      final db = Pool.withEndpoints(
        [await server.endpoint()],
        settings: PoolSettings(
          maxConnectionCount: 1,
        ),
      );

      for (var i = 0; i < 10; i++) {
        await expectLater(
            () => db.run((c) => c.execute('select x;')), throwsException);
      }

      await db.execute('SELECT 1');
    });

    test('empty query does not lock up pool instance', () async {
      final db = Pool.withEndpoints(
        [await server.endpoint()],
        settings: PoolSettings(
          maxConnectionCount: 1,
        ),
      );

      // this doesn't throw but it causes the connection to close
      await db.execute('-- test');
      await db.execute('SELECT 1');
    });
  });

  withPostgresServer('limit pool connections', (server) {
    test('can limit concurrent connections', () async {
      final pool = Pool.withEndpoints(
        [await server.endpoint()],
        settings: PoolSettings(maxConnectionCount: 2),
      );
      addTearDown(pool.close);

      final completeFirstTwo = Completer();
      final didInvokeThird = Completer();

      // Take two connections
      unawaited(pool.withConnection((connection) => completeFirstTwo.future));
      unawaited(pool.withConnection((connection) => completeFirstTwo.future));

      // Creating a third one should block.

      unawaited(pool.withConnection((connection) async {
        didInvokeThird.complete();
      }));

      await pumpEventQueue();
      expect(didInvokeThird.isCompleted, isFalse);

      completeFirstTwo.complete();
      await didInvokeThird.future;
    });
  });

  withPostgresServer('closes old connections', (server) {
    test('when new connection required it', () async {
      final pool = Pool.withEndpoints(
        [await server.endpoint()],
        settings: PoolSettings(maxConnectionCount: 1),
      );
      addTearDown(pool.close);

      final results = <int>{};
      final futures = <Future>{};
      for (var i = 0; i < 10; i++) {
        final f = pool.withConnection((c) async {
          await c.execute('SELECT $i');
          results.add(i);
        }, settings: PoolSettings(applicationName: 'x$i'));
        futures.add(f);
      }
      await Future.wait(futures);
      expect(results, hasLength(10));
    });
  });

  withPostgresServer('Connection settings', (server) {
    test('runs connection.onOpen callback', () async {
      final pool = Pool.withEndpoints(
        [await server.endpoint()],
        settings: PoolSettings(
          maxConnectionCount: 1,
          onOpen: (c) async {
            await c.execute('SET application_name TO myapp;');
          },
        ),
      );
      addTearDown(pool.close);

      final name = (await pool.execute('SHOW application_name;')).single.single;
      expect(name, 'myapp');
    });
  });
}
