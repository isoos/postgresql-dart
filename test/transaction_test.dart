// ignore_for_file: unawaited_futures
import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  usePostgresDocker();
  group('Transaction behavior', () {
    late PostgreSQLConnection conn;

    setUp(() async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');
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

    test("A transaction doesn't have to await on queries", () async {
      conn.transaction((ctx) async {
        ctx.query('INSERT INTO t (id) VALUES (1)');
        ctx.query('INSERT INTO t (id) VALUES (2)');
        ctx.query('INSERT INTO t (id) VALUES (3)');
      });

      final total = await conn.query('SELECT id FROM t');
      expect(total, [
        [1],
        [2],
        [3]
      ]);
    });

    test(
        "A transaction doesn't have to await on queries, when the last query fails, it still emits an error from the transaction",
        () async {
      dynamic transactionError;
      final rs = await conn.query('SELECT 1');
      await conn.transaction((ctx) async {
        ctx.query('INSERT INTO t (id) VALUES (1)');
        ctx.query('INSERT INTO t (id) VALUES (2)');
        ctx.query("INSERT INTO t (id) VALUES ('foo')").catchError((e) => rs);
      }).catchError((e) => transactionError = e);

      expect(transactionError, isNotNull);

      final total = await conn.query('SELECT id FROM t');
      expect(total, []);
    });

    test(
        "A transaction doesn't have to await on queries, when the non-last query fails, it still emits an error from the transaction",
        () async {
      dynamic failingQueryError;
      dynamic pendingQueryError;
      dynamic transactionError;
      final rs = await conn.query('SELECT 1');
      await conn.transaction((ctx) async {
        ctx.query('INSERT INTO t (id) VALUES (1)');
        ctx.query("INSERT INTO t (id) VALUES ('foo')").catchError((e) {
          failingQueryError = e;
          return rs;
        });
        ctx.query('INSERT INTO t (id) VALUES (2)').catchError((e) {
          pendingQueryError = e;
          return rs;
        });
      }).catchError((e) => transactionError = e);
      expect(transactionError, isNotNull);
      expect(failingQueryError.toString(), contains('invalid input'));
      expect(
          pendingQueryError.toString(), contains('failed prior to execution'));
      final total = await conn.query('SELECT id FROM t');
      expect(total, []);
    });

    test(
        'A transaction with a rollback and non-await queries rolls back transaction',
        () async {
      final rs = await conn.query('select 1');
      final errs = [];
      await conn.transaction((ctx) async {
        final errsAdd = (e) {
          errs.add(e);
          return rs;
        };
        ctx.query('INSERT INTO t (id) VALUES (1)').catchError(errsAdd);
        ctx.query('INSERT INTO t (id) VALUES (2)').catchError(errsAdd);
        ctx.cancelTransaction();
        ctx.query('INSERT INTO t (id) VALUES (3)').catchError((e) {});
      });

      final total = await conn.query('SELECT id FROM t');
      expect(total, []);

      expect(errs.length, 2);
    });

    test(
        'A transaction that mixes awaiting and non-awaiting queries fails gracefully when an awaited query fails',
        () async {
      dynamic transactionError;
      await conn.transaction((ctx) async {
        ctx.query('INSERT INTO t (id) VALUES (1)');
        await ctx.query("INSERT INTO t (id) VALUES ('foo')").catchError((_) {});
        ctx.query('INSERT INTO t (id) VALUES (2)').catchError((_) {});
      }).catchError((e) => transactionError = e);

      expect(transactionError, isNotNull);
      final total = await conn.query('SELECT id FROM t');
      expect(total, []);
    });

    test(
        'A transaction that mixes awaiting and non-awaiting queries fails gracefully when an unawaited query fails',
        () async {
      dynamic transactionError;
      final rs = conn.query('SELECT 1');
      await conn.transaction((ctx) async {
        await ctx.query('INSERT INTO t (id) VALUES (1)');
        ctx.query("INSERT INTO t (id) VALUES ('foo')").catchError((_) => rs);
        await ctx.query('INSERT INTO t (id) VALUES (2)').catchError((_) => rs);
      }).catchError((e) => transactionError = e);

      expect(transactionError, isNotNull);
      final total = await conn.query('SELECT id FROM t');
      expect(total, []);
    });
  });

  // A transaction can fail for three reasons: query error, exception in code, or a rollback.
  // After a transaction fails, the changes must be rolled back, it should continue with pending queries, pending transactions, later queries, later transactions

  group('Transaction:Query recovery', () {
    late PostgreSQLConnection conn;

    setUp(() async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');
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

  group('Transaction:Exception recovery', () {
    late PostgreSQLConnection conn;

    setUp(() async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');
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

    test(
        'If exception thrown while preparing query, transaction gets rolled back',
        () async {
      try {
        final rs = conn.query('SELECT 1');
        await conn.transaction((c) async {
          await c.query('INSERT INTO t (id) VALUES (1)');

          c.query('INSERT INTO t (id) VALUES (@id:int4)',
              substitutionValues: {'id': 'foobar'}).catchError((_) => rs);
          await c.query('INSERT INTO t (id) VALUES (2)');
        });
        expect(true, false);
      } catch (e) {
        expect(e is FormatException, true);
      }

      final noRows = await conn.query('SELECT id FROM t');
      expect(noRows, []);
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

  group('Transaction:Rollback recovery', () {
    late PostgreSQLConnection conn;

    setUp(() async {
      conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');
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
