// ignore_for_file: unawaited_futures
import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('Transaction behavior', (server) {
    late PgConnection conn;

    setUp(() async {
      conn = await server.newConnection();
      await conn.execute('CREATE TEMPORARY TABLE t (id INT UNIQUE)');
    });

    tearDown(() async {
      await conn.close();
    });

    test('Rows are Lists of column values', () async {
      await conn.execute('INSERT INTO t (id) VALUES (1)');

      final outValue = await conn.runTx((ctx) async {
        return await ctx.execute('SELECT * FROM t WHERE id = @id:int4 LIMIT 1',
            parameters: {'id': 1});
      });

      expect(outValue, [
        [1]
      ]);
    });

    test('Send successful transaction succeeds, returns returned value',
        () async {
      final outResult = await conn.runTx((c) async {
        await c.execute('INSERT INTO t (id) VALUES (1)');

        return await c.execute('SELECT id FROM t');
      });
      expect(outResult, [
        [1]
      ]);

      final result = await conn.execute('SELECT id FROM t');
      expect(result, [
        [1]
      ]);
    });

    test('Query during transaction must wait until transaction is finished',
        () async {
      final orderEnsurer = [];
      final nextCompleter = Completer.sync();
      final outResult = conn.runTx((c) async {
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
      await conn.execute('INSERT INTO t (id) VALUES (2)');
      orderEnsurer.add(12);
      final laterResults = await conn.execute('SELECT id FROM t');
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

      final firstTransactionFuture = conn.runTx((c) async {
        orderEnsurer.add(11);
        await c.execute('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(12);
        final result = await c.execute('SELECT id FROM t');
        orderEnsurer.add(13);

        return result;
      });

      final secondTransactionFuture = conn.runTx((c) async {
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

    test('May intentionally rollback transaction', () async {
      final rollback = Exception();

      await expectLater(conn.runTx((c) async {
        await c.execute('INSERT INTO t (id) VALUES (1)');
        throw rollback;
      }), throwsA(rollback));

      final result = await conn.execute('SELECT id FROM t');
      expect(result, []);
    });

    test('A transaction does not preempt pending queries', () async {
      // Add a few insert queries but don't await, then do a transaction that does a fetch,
      // make sure that transaction contains all of the elements.
      // This makes use of the implementation detail that simple executes
      // (no result rows, no parameters) are locking the connection directly.
      conn.execute('INSERT INTO t (id) VALUES (1)', ignoreRows: true);
      conn.execute('INSERT INTO t (id) VALUES (2)', ignoreRows: true);
      conn.execute('INSERT INTO t (id) VALUES (3)', ignoreRows: true);

      final results = await conn.runTx((ctx) async {
        return await ctx.execute('SELECT id FROM t');
      });
      expect(results, [
        [1],
        [2],
        [3]
      ]);
    });

    test("A transaction doesn't have to await on queries", () async {
      conn.runTx((ctx) async {
        ctx.execute('INSERT INTO t (id) VALUES (1)');
        ctx.execute('INSERT INTO t (id) VALUES (2)');
        ctx.execute('INSERT INTO t (id) VALUES (3)');
      });

      final total = await conn.execute('SELECT id FROM t');
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
      final rs = await conn.execute('SELECT 1');
      await conn.runTx((ctx) async {
        ctx.execute('INSERT INTO t (id) VALUES (1)');
        ctx.execute('INSERT INTO t (id) VALUES (2)');
        ctx.execute("INSERT INTO t (id) VALUES ('foo')").catchError((e) => rs);
      }).catchError((e) => transactionError = e);

      expect(transactionError, isNotNull);

      final total = await conn.execute('SELECT id FROM t');
      expect(total, []);
    });

    test(
        "A transaction doesn't have to await on queries, when the non-last query fails, it still emits an error from the transaction",
        () async {
      dynamic failingQueryError;
      dynamic pendingQueryError;
      dynamic transactionError;
      final rs = await conn.execute('SELECT 1');
      await conn.runTx((ctx) async {
        ctx.execute('INSERT INTO t (id) VALUES (1)');
        ctx.execute("INSERT INTO t (id) VALUES ('foo')").catchError((e) {
          failingQueryError = e;
          return rs;
        });
        ctx.execute('INSERT INTO t (id) VALUES (2)').catchError((e) {
          pendingQueryError = e;
          return rs;
        });
      }).catchError((e) => transactionError = e);
      expect(transactionError, isNotNull);
      expect(failingQueryError.toString(), contains('invalid input'));
      expect(
          pendingQueryError.toString(), contains('failed prior to execution'));
      final total = await conn.execute('SELECT id FROM t');
      expect(total, []);
    });

    test(
        'A transaction with a rollback and non-await queries rolls back transaction',
        () async {
      final rs = await conn.execute('select 1');
      final rollback = Exception();
      final errs = [];

      await expectLater(conn.runTx((ctx) async {
        PgResult errsAdd(e) {
          errs.add(e);
          return rs;
        }

        ctx.execute('INSERT INTO t (id) VALUES (1)').catchError(errsAdd);
        ctx.execute('INSERT INTO t (id) VALUES (2)').catchError(errsAdd);
        throw rollback;
      }), throwsA(rollback));

      final total = await conn.execute('SELECT id FROM t');
      expect(total, []);

      expect(errs.length, 2);
    });

    test(
        'A transaction that mixes awaiting and non-awaiting queries fails gracefully when an awaited query fails',
        () async {
      dynamic transactionError;
      await conn.runTx((ctx) async {
        unawaited(ctx.execute('INSERT INTO t (id) VALUES (1)'));
        // ignore: body_might_complete_normally_catch_error
        await ctx
            .execute("INSERT INTO t (id) VALUES ('foo')")
            .catchError((_) {});
        unawaited(
            // ignore: body_might_complete_normally_catch_error
            ctx.execute('INSERT INTO t (id) VALUES (2)').catchError((_) {}));
      }).catchError((e) => transactionError = e);

      expect(transactionError, isNotNull);
      final total = await conn.execute('SELECT id FROM t');
      expect(total, []);
    });

    test(
        'A transaction that mixes awaiting and non-awaiting queries fails gracefully when an unawaited query fails',
        () async {
      dynamic transactionError;
      final rs = conn.execute('SELECT 1');
      await conn.runTx((ctx) async {
        await ctx.execute('INSERT INTO t (id) VALUES (1)');
        ctx.execute("INSERT INTO t (id) VALUES ('foo')").catchError((_) => rs);
        await ctx
            .execute('INSERT INTO t (id) VALUES (2)')
            .catchError((_) => rs);
      }).catchError((e) => transactionError = e);

      expect(transactionError, isNotNull);
      final total = await conn.execute('SELECT id FROM t');
      expect(total, []);
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
