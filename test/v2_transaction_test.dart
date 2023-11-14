// ignore_for_file: unawaited_futures
import 'dart:async';

import 'package:postgres/legacy.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('Transaction behavior', (server) {
    late PostgreSQLConnection conn;

    setUp(() async {
      conn = await server.newPostgreSQLConnection();
      await conn.open();
      await conn.execute('CREATE TEMPORARY TABLE t (id INT UNIQUE)');
    });

    tearDown(() async {
      await conn.close();
    });

    test('Rows are Lists of column values', () async {
      await conn.execute('INSERT INTO t (id) VALUES (1)');

      final outValue = await conn.transaction((ctx) async {
        return await ctx.query('SELECT * FROM t WHERE id = @id LIMIT 1',
            substitutionValues: {'id': 1});
      }) as List;

      expect(outValue.length, 1);
      expect(outValue.first is List, true);
      final firstItem = outValue.first as List;
      expect(firstItem.length, 1);
      expect(firstItem.first, 1);
    });

    test('Send successful transaction succeeds, returns returned value',
        () async {
      final outResult = await conn.transaction((c) async {
        await c.query('INSERT INTO t (id) VALUES (1)');

        return await c.query('SELECT id FROM t');
      });
      expect(outResult, [
        [1]
      ]);

      final result = await conn.query('SELECT id FROM t');
      expect(result, [
        [1]
      ]);
    });

    test('Query during transaction must wait until transaction is finished',
        () async {
      final orderEnsurer = [];
      final nextCompleter = Completer.sync();
      final outResult = conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(2);
        nextCompleter.complete();
        final result = await c.query('SELECT id FROM t');
        orderEnsurer.add(3);

        return result;
      });

      await nextCompleter.future;
      orderEnsurer.add(11);
      await conn.query('INSERT INTO t (id) VALUES (2)');
      orderEnsurer.add(12);
      final laterResults = await conn.query('SELECT id FROM t');
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

      final firstTransactionFuture = conn.transaction((c) async {
        orderEnsurer.add(11);
        await c.query('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(12);
        final result = await c.query('SELECT id FROM t');
        orderEnsurer.add(13);

        return result;
      });

      final secondTransactionFuture = conn.transaction((c) async {
        orderEnsurer.add(21);
        await c.query('INSERT INTO t (id) VALUES (2)');
        orderEnsurer.add(22);
        final result = await c.query('SELECT id FROM t');
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

    test('May intentionally rollback transaction', () async {
      var reached = false;
      await conn.transaction((c) async {
        await c.query('INSERT INTO t (id) VALUES (1)');
        c.cancelTransaction();

        reached = true;
        await c.query('INSERT INTO t (id) VALUES (2)');
      });

      expect(reached, false);
      final result = await conn.query('SELECT id FROM t');
      expect(result, []);
    });

    test('Intentional rollback on non-transaction has no impact', () async {
      conn.cancelTransaction();
      final result = await conn.query('SELECT id FROM t');
      expect(result, []);
    });

    test('Intentional rollback from outside of a transaction has no impact',
        () async {
      final orderEnsurer = [];
      final nextCompleter = Completer.sync();
      final outResult = conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(2);
        nextCompleter.complete();
        final result = await c.query('SELECT id FROM t');
        orderEnsurer.add(3);

        return result;
      });

      await nextCompleter.future;
      conn.cancelTransaction();

      orderEnsurer.add(11);
      final results = await outResult;

      expect(orderEnsurer, [1, 2, 11, 3]);
      expect(results, [
        [1]
      ]);
    });

    test('A transaction does not preempt pending queries', () async {
      // Add a few insert queries but don't await, then do a transaction that does a fetch,
      // make sure that transaction contains all of the elements.
      conn.execute('INSERT INTO t (id) VALUES (1)');
      conn.execute('INSERT INTO t (id) VALUES (2)');
      conn.execute('INSERT INTO t (id) VALUES (3)');

      final results = await conn.transaction((ctx) async {
        return await ctx.query('SELECT id FROM t');
      });
      expect(results, [
        [1],
        [2],
        [3]
      ]);
    });
  });

  // A transaction can fail for three reasons: query error, exception in code, or a rollback.
  // After a transaction fails, the changes must be rolled back, it should continue with pending queries, pending transactions, later queries, later transactions

  withPostgresServer('Transaction:Query recovery', (server) {
    late PostgreSQLConnection conn;

    setUp(() async {
      conn = await server.newPostgreSQLConnection();
      await conn.open();
      await conn.execute('CREATE TEMPORARY TABLE t (id INT UNIQUE)');
    });

    tearDown(() async {
      await conn.close();
    });

    test('Is rolled back/executes later query', () async {
      try {
        await conn.transaction((c) async {
          await c.query('INSERT INTO t (id) VALUES (1)');
          final oneRow = await c.query('SELECT id FROM t');
          expect(oneRow, [
            [1]
          ]);

          // This will error
          await c.query('INSERT INTO t (id) VALUES (1)');
        });
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.message, contains('unique constraint'));
      }

      final noRows = await conn.query('SELECT id FROM t');
      expect(noRows, []);
    });

    test('Executes pending query', () async {
      final orderEnsurer = [];

      conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(2);

        // This will error
        await c.query('INSERT INTO t (id) VALUES (1)');
      }).catchError((e) => null);

      orderEnsurer.add(11);
      final result = await conn.query('SELECT id FROM t');
      orderEnsurer.add(12);

      expect(orderEnsurer, [11, 1, 2, 12]);
      expect(result, []);
    });

    test('Executes pending transaction', () async {
      final orderEnsurer = [];

      conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(2);

        // This will error
        await c.query('INSERT INTO t (id) VALUES (1)');
      }).catchError((e) => null);

      final result = await conn.transaction((ctx) async {
        orderEnsurer.add(11);
        return await ctx.query('SELECT id FROM t');
      });
      orderEnsurer.add(12);

      expect(orderEnsurer, [1, 2, 11, 12]);
      expect(result, []);
    });

    test('Executes later transaction', () async {
      try {
        await conn.transaction((c) async {
          await c.query('INSERT INTO t (id) VALUES (1)');
          final oneRow = await c.query('SELECT id FROM t');
          expect(oneRow, [
            [1]
          ]);

          // This will error
          await c.query('INSERT INTO t (id) VALUES (1)');
        });
        expect(true, false);
      } on PostgreSQLException {
        // ignore
      }

      final result = await conn.transaction((ctx) async {
        return await ctx.query('SELECT id FROM t');
      });
      expect(result, []);
    });
  });

  withPostgresServer('Transaction:Exception recovery', (server) {
    late PostgreSQLConnection conn;

    setUp(() async {
      conn = await server.newPostgreSQLConnection();
      await conn.open();
      await conn.execute('CREATE TEMPORARY TABLE t (id INT UNIQUE)');
    });

    tearDown(() async {
      await conn.close();
    });

    test('Is rolled back/executes later query', () async {
      try {
        await conn.transaction((c) async {
          await c.query('INSERT INTO t (id) VALUES (1)');
          throw Exception('foo');
        });
        expect(true, false);
      } on Exception {
        // ignore
      }

      final noRows = await conn.query('SELECT id FROM t');
      expect(noRows, []);
    });

    test('Executes pending query', () async {
      final orderEnsurer = [];

      conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(2);
        throw Exception('foo');
      }).catchError((e) => null);

      orderEnsurer.add(11);
      final result = await conn.query('SELECT id FROM t');
      orderEnsurer.add(12);

      expect(orderEnsurer, [11, 1, 2, 12]);
      expect(result, []);
    });

    test('Executes pending transaction', () async {
      final orderEnsurer = [];

      conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(2);
        throw Exception('foo');
      }).catchError((e) => null);

      final result = await conn.transaction((ctx) async {
        orderEnsurer.add(11);
        return await ctx.query('SELECT id FROM t');
      });
      orderEnsurer.add(12);

      expect(orderEnsurer, [1, 2, 11, 12]);
      expect(result, []);
    });

    test('Executes later transaction', () async {
      try {
        await conn.transaction((c) async {
          await c.query('INSERT INTO t (id) VALUES (1)');
          throw Exception('foo');
        });
        expect(true, false);
      } on Exception {
        // ignore
      }

      final result = await conn.transaction((ctx) async {
        return await ctx.query('SELECT id FROM t');
      });
      expect(result, []);
    });

    test('Async query failure prevents closure from continuing', () async {
      var reached = false;

      try {
        await conn.transaction((c) async {
          await c.query('INSERT INTO t (id) VALUES (1)');
          await c.query("INSERT INTO t (id) VALUE ('foo') RETURNING id");

          reached = true;
          await c.query('INSERT INTO t (id) VALUES (2)');
        });
        fail('unreachable');
      } on PostgreSQLException {
        // ignore
      }

      expect(reached, false);
      final res = await conn.query('SELECT * FROM t');
      expect(res, []);
    });

    test(
        'When exception thrown in unawaited on future, transaction is rolled back',
        () async {
      try {
        final rs = conn.query('SELECT 1');
        await conn.transaction((c) async {
          await c.query('INSERT INTO t (id) VALUES (1)');
          c
              .query("INSERT INTO t (id) VALUE ('foo') RETURNING id")
              .catchError((_) => rs);
          await c.query('INSERT INTO t (id) VALUES (2)');
        });
        fail('unreachable');
      } on PostgreSQLException {
        // ignore
      }

      final res = await conn.query('SELECT * FROM t');
      expect(res, []);
    });
  });

  withPostgresServer('Transaction:Rollback recovery', (server) {
    late PostgreSQLConnection conn;

    setUp(() async {
      conn = await server.newPostgreSQLConnection();
      await conn.open();
      await conn.execute('CREATE TEMPORARY TABLE t (id INT UNIQUE)');
    });

    tearDown(() async {
      await conn.close();
    });

    test('Is rolled back/executes later query', () async {
      final result = await conn.transaction((c) async {
        await c.query('INSERT INTO t (id) VALUES (1)');
        c.cancelTransaction();
        await c.query('INSERT INTO t (id) VALUES (2)');
      });

      expect(result is PostgreSQLRollback, true);

      final noRows = await conn.query('SELECT id FROM t');
      expect(noRows, []);
    });

    test('Executes pending query', () async {
      final orderEnsurer = [];

      conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(2);
        c.cancelTransaction();
        await c.query('INSERT INTO t (id) VALUES (2)');
      });

      orderEnsurer.add(11);
      final result = await conn.query('SELECT id FROM t');
      orderEnsurer.add(12);

      expect(orderEnsurer, [11, 1, 2, 12]);
      expect(result, []);
    });

    test('Executes pending transaction', () async {
      final orderEnsurer = [];

      conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(2);
        c.cancelTransaction();
        await c.query('INSERT INTO t (id) VALUES (2)');
        orderEnsurer.add(3);
      });

      final result = await conn.transaction((ctx) async {
        orderEnsurer.add(11);
        return await ctx.query('SELECT id FROM t');
      });
      orderEnsurer.add(12);

      expect(orderEnsurer, [1, 2, 11, 12]);
      expect(result, []);
    });

    test('Executes later transaction', () async {
      dynamic result = await conn.transaction((c) async {
        await c.query('INSERT INTO t (id) VALUES (1)');
        c.cancelTransaction();
        await c.query('INSERT INTO t (id) VALUES (2)');
      });
      expect(result is PostgreSQLRollback, true);

      result = await conn.transaction((ctx) async {
        return await ctx.query('SELECT id FROM t');
      });
      expect(result, []);
    });

    test('can start transactions manually', () async {
      await conn.execute('BEGIN');
      await conn.execute(
        'INSERT INTO t VALUES (@a)',
        substitutionValues: {'a': 123},
      );
      await conn.execute('ROLLBACK');

      await expectLater(conn.query('SELECT * FROM t'), completion(isEmpty));
    });
  });
}
