// ignore_for_file: unawaited_futures
import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('Transaction behavior', (server) {
    late Connection conn;

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
        return await ctx.execute(
            Sql.named('SELECT * FROM t WHERE id = @id:int4 LIMIT 1'),
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

    test('Connection query during transaction will throw exception.', () async {
      try {
        await conn.runTx((ctx) async {
          await conn.execute('SELECT 1');
          await ctx.execute('INSERT INTO t (id) VALUES (1)');
        });
        fail('unreachable');
      } on PgException catch (e) {
        expect(e.message, contains('runTx'));
        // ignore
      }

      expect(await conn.execute('SELECT * from t'), hasLength(0));
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

    test("A transaction doesn't have to await on simple queries", () async {
      conn.runTx((ctx) async {
        ctx.execute('INSERT INTO t (id) VALUES (1)',
            queryMode: QueryMode.simple);
        ctx.execute('INSERT INTO t (id) VALUES (2)',
            queryMode: QueryMode.simple);
        ctx.execute('INSERT INTO t (id) VALUES (3)',
            queryMode: QueryMode.simple);
      });

      final total = await conn.execute('SELECT id FROM t');
      expect(total, [
        [1],
        [2],
        [3]
      ]);
    });

    test('A transaction has to await extended queries', () async {
      await conn.runTx((session) async {
        expect(
          session.execute('select 1;'),
          throwsA(isA<PgException>().having((e) => e.message, 'message',
              contains('did you forget to await a statement?'))),
        );
      });
    });

    test(
        "A transaction doesn't have to await on simple queries, when the last query fails, it still emits an error from the transaction",
        () async {
      dynamic transactionError;
      final rs = await conn.execute('SELECT 1');
      await conn.runTx<void>((ctx) async {
        ctx.execute('INSERT INTO t (id) VALUES (1)',
            queryMode: QueryMode.simple);
        ctx.execute('INSERT INTO t (id) VALUES (2)',
            queryMode: QueryMode.simple);
        ctx
            .execute("INSERT INTO t (id) VALUES ('foo')",
                queryMode: QueryMode.simple)
            .catchError((e) => rs);
      }).catchError((e) => transactionError = e);

      expect(transactionError, isNotNull);

      final total = await conn.execute('SELECT id FROM t');
      expect(total, []);
    });

    test(
        "A transaction doesn't have to await on simple queries, when the non-last query fails, it still emits an error from the transaction",
        () async {
      dynamic failingQueryError;
      dynamic pendingQueryError;
      dynamic transactionError;
      final rs = await conn.execute('SELECT 1');
      await conn.runTx<void>((ctx) async {
        ctx.execute('INSERT INTO t (id) VALUES (1)',
            queryMode: QueryMode.simple);
        ctx
            .execute("INSERT INTO t (id) VALUES ('foo')",
                queryMode: QueryMode.simple)
            .catchError((e) {
          failingQueryError = e;
          return rs;
        });
        ctx
            .execute('INSERT INTO t (id) VALUES (2)',
                queryMode: QueryMode.simple)
            .catchError((e) {
          pendingQueryError = e;
          return rs;
        });
      }).catchError((e) => transactionError = e);
      expect(transactionError, isNotNull);
      expect(failingQueryError.toString(), contains('invalid input'));
      expect(pendingQueryError.toString(),
          contains('current transaction is aborted'));
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
        Result errsAdd(e) {
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
      final rs = await conn.execute('select 1');

      dynamic transactionError;
      await conn.runTx<void>((ctx) async {
        unawaited(ctx.execute('INSERT INTO t (id) VALUES (1)',
            queryMode: QueryMode.simple));
        try {
          await ctx.execute("INSERT INTO t (id) VALUES ('foo')");
        } on PgException {
          // expected
        }

        unawaited(ctx
            .execute('INSERT INTO t (id) VALUES (2)',
                queryMode: QueryMode.simple)
            .catchError((_) => rs));
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
      await conn.runTx<void>((ctx) async {
        await ctx.execute('INSERT INTO t (id) VALUES (1)');
        ctx
            .execute("INSERT INTO t (id) VALUES ('foo')",
                queryMode: QueryMode.simple)
            .catchError((_) => rs);
        try {
          await ctx.execute('INSERT INTO t (id) VALUES (2)');
        } on PgException {
          // expected
        }
      }).catchError((e) => transactionError = e);

      expect(transactionError, isNotNull);
      final total = await conn.execute('SELECT id FROM t');
      expect(total, []);
    });

    test('isOpen and closed', () async {
      late Session leakedTransaction;
      var afterTransaction = false;

      await conn.runTx(expectAsync1((session) async {
        leakedTransaction = session;
        expect(session.isOpen, isTrue);

        // .closed should complete before the runTx future
        expectLater(
            session.closed.then((_) => afterTransaction), completion(isFalse));
      }));
      afterTransaction = true;

      expect(leakedTransaction.isOpen, isFalse);
    });
  });

  // A transaction can fail for three reasons: query error, exception in code, or a rollback.
  // After a transaction fails, the changes must be rolled back, it should continue with pending queries, pending transactions, later queries, later transactions

  withPostgresServer('Transaction:Query recovery', (server) {
    late Connection conn;

    setUp(() async {
      conn = await server.newConnection();
      await conn.execute('CREATE TEMPORARY TABLE t (id INT UNIQUE)');
    });

    tearDown(() async {
      await conn.close();
    });

    test('Is rolled back/executes later query', () async {
      try {
        await conn.runTx((c) async {
          await c.execute('INSERT INTO t (id) VALUES (1)');
          final oneRow = await c.execute('SELECT id FROM t');
          expect(oneRow, [
            [1]
          ]);

          // This will error
          await c.execute('INSERT INTO t (id) VALUES (1)');
        });
        fail('Should have thrown an exception');
      } on PgException catch (e) {
        expect(e.message, contains('unique constraint'));
      }

      final noRows = await conn.execute('SELECT id FROM t');
      expect(noRows, []);
    });

    test('Executes pending query', () async {
      final orderEnsurer = [];

      conn.runTx((c) async {
        orderEnsurer.add(1);
        await c.execute('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(2);

        // This will error
        await c.execute('INSERT INTO t (id) VALUES (1)');
      }).catchError((e) => null);

      orderEnsurer.add(11);
      final result = await conn.execute('SELECT id FROM t');
      orderEnsurer.add(12);

      expect(orderEnsurer, [11, 1, 2, 12]);
      expect(result, []);
    });

    test('Executes pending transaction', () async {
      final orderEnsurer = [];

      conn.runTx((c) async {
        orderEnsurer.add(1);
        await c.execute('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(2);

        // This will error
        await c.execute('INSERT INTO t (id) VALUES (1)');
      }).catchError((e) => null);

      final result = await conn.runTx((ctx) async {
        orderEnsurer.add(11);
        return await ctx.execute('SELECT id FROM t');
      });
      orderEnsurer.add(12);

      expect(orderEnsurer, [1, 2, 11, 12]);
      expect(result, []);
    });

    test('Executes later transaction', () async {
      try {
        await conn.runTx((c) async {
          await c.execute('INSERT INTO t (id) VALUES (1)');
          final oneRow = await c.execute('SELECT id FROM t');
          expect(oneRow, [
            [1]
          ]);

          // This will error
          await c.execute('INSERT INTO t (id) VALUES (1)');
        });
        expect(true, false);
      } on PgException {
        // ignore
      }

      final result = await conn.runTx((ctx) async {
        return await ctx.execute('SELECT id FROM t');
      });
      expect(result, []);
    });
  });

  withPostgresServer('Transaction:Exception recovery', (server) {
    late Connection conn;

    setUp(() async {
      conn = await server.newConnection();
      await conn.execute('CREATE TEMPORARY TABLE t (id INT UNIQUE)');
    });

    tearDown(() async {
      await conn.close();
    });

    test('Is rolled back/executes later query', () async {
      final exception = Exception('rollback');

      await expectLater(conn.runTx((c) async {
        await c.execute('INSERT INTO t (id) VALUES (1)');
        throw exception;
      }), throwsA(exception));

      final noRows = await conn.execute('SELECT id FROM t');
      expect(noRows, []);
    });

    test('Executes pending query', () async {
      final orderEnsurer = [];

      conn.runTx<void>((c) async {
        orderEnsurer.add(1);
        await c.execute('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(2);
        throw Exception('foo');
      }).catchError((e) => null);

      orderEnsurer.add(11);
      final result = await conn.execute('SELECT id FROM t');
      orderEnsurer.add(12);

      expect(orderEnsurer, [11, 1, 2, 12]);
      expect(result, []);
    });

    test('Executes pending transaction', () async {
      final orderEnsurer = [];

      conn.runTx<void>((c) async {
        orderEnsurer.add(1);
        await c.execute('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(2);
        throw Exception('foo');
      }).catchError((e) => null);

      final result = await conn.runTx((ctx) async {
        orderEnsurer.add(11);
        return await ctx.execute('SELECT id FROM t');
      });
      orderEnsurer.add(12);

      expect(orderEnsurer, [1, 2, 11, 12]);
      expect(result, []);
    });

    test('Executes later transaction', () async {
      await expectLater(conn.runTx((c) async {
        await c.execute('INSERT INTO t (id) VALUES (1)');
        throw Exception('foo');
      }), throwsA(isException));

      final result = await conn.runTx((ctx) async {
        return await ctx.execute('SELECT id FROM t');
      });
      expect(result, []);
    });

    test("Caught Dart errors don't roll back transactions", () async {
      await conn.runTx((c) async {
        await c.execute('INSERT INTO t (id) VALUES (1)');

        // The mismatched type is caught in Dart, but unawaited here
        expect(
            c.execute(Sql.named('INSERT INTO t (id) VALUES (@id:int4)'),
                parameters: {'id': 'foobar'}),
            throwsA(isA<FormatException>()));

        await c.execute('INSERT INTO t (id) VALUES (2)');
      });

      final rows = await conn.execute('SELECT id FROM t');
      expect(rows, [
        [1],
        [2]
      ]);
    });

    test('Async query failure prevents closure from continuing', () async {
      var reached = false;

      try {
        await conn.runTx((c) async {
          await c.execute('INSERT INTO t (id) VALUES (1)');
          await c.execute("INSERT INTO t (id) VALUE ('foo') RETURNING id");

          reached = true;
          await c.execute('INSERT INTO t (id) VALUES (2)');
        });
        fail('unreachable');
      } on PgException {
        // ignore
      }

      expect(reached, false);
      final res = await conn.execute('SELECT * FROM t');
      expect(res, []);
    });

    test(
        'When exception thrown in unawaited on future, transaction is rolled back',
        () async {
      try {
        final rs = conn.execute('SELECT 1');
        await conn.runTx((c) async {
          await c.execute('INSERT INTO t (id) VALUES (1)');
          c
              .execute("INSERT INTO t (id) VALUE ('foo') RETURNING id",
                  queryMode: QueryMode.simple)
              .catchError((_) => rs);
          await c.execute('INSERT INTO t (id) VALUES (2)');
        });
        fail('unreachable');
      } on PgException {
        // ignore
      }

      final res = await conn.execute('SELECT * FROM t');
      expect(res, []);
    });
  });

  withPostgresServer('Transaction:Rollback recovery', (server) {
    late Connection conn;

    setUp(() async {
      conn = await server.newConnection();
      await conn.execute('CREATE TEMPORARY TABLE t (id INT UNIQUE)');
    });

    tearDown(() async {
      await conn.close();
    });

    test('Is rolled back/executes later query after exception', () async {
      expect(conn.runTx((c) async {
        await c.execute('INSERT INTO t (id) VALUES (1)');
        throw Exception();
      }), throwsA(isException));

      final noRows = await conn.execute('SELECT id FROM t');
      expect(noRows, []);
    });

    test('Is rolled back/executes later query after calling `rollback()`.',
        () async {
      final rs = await conn.runTx((c) async {
        await c.execute('INSERT INTO t (id) VALUES (1)');
        final stm = await c.prepare('SELECT 1');
        expect(await stm.run([]), hasLength(1));
        await c.rollback();
        await expectLater(() => c.execute('SELECT 1'), throwsException);
        await expectLater(() => stm.run([]), throwsException);
        return 123;
      });
      expect(rs, 123);

      final noRows = await conn.execute('SELECT id FROM t');
      expect(noRows, []);
    });

    test('Executes pending query', () async {
      final orderEnsurer = [];

      conn.runTx<void>((c) async {
        orderEnsurer.add(1);
        await c.execute('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(2);
        throw Exception();
      }).catchError((_) => {});

      orderEnsurer.add(11);
      final result = await conn.execute('SELECT id FROM t');
      orderEnsurer.add(12);

      expect(orderEnsurer, [11, 1, 2, 12]);
      expect(result, []);
    });

    test('Executes pending transaction', () async {
      final orderEnsurer = [];

      expect(conn.runTx((c) async {
        orderEnsurer.add(1);
        await c.execute('INSERT INTO t (id) VALUES (1)');
        orderEnsurer.add(2);
        throw Exception();
      }), throwsA(isException));

      final result = await conn.runTx((ctx) async {
        orderEnsurer.add(11);
        return await ctx.execute('SELECT id FROM t');
      });
      orderEnsurer.add(12);

      expect(orderEnsurer, [1, 2, 11, 12]);
      expect(result, []);
    });

    test('Executes later transaction', () async {
      await expectLater(conn.runTx((c) async {
        await c.execute('INSERT INTO t (id) VALUES (1)');
        throw Exception();
      }), throwsA(isException));

      final result = await conn.runTx((ctx) async {
        return await ctx.execute('SELECT id FROM t');
      });
      expect(result, []);
    });

    test('can start transactions manually', () async {
      await conn.execute('BEGIN');
      await conn.execute(
        Sql.named('INSERT INTO t VALUES (@a:int4)'),
        parameters: {'a': 123},
      );
      await conn.execute('ROLLBACK');

      await expectLater(conn.execute('SELECT * FROM t'), completion(isEmpty));
    });
  });

  withPostgresServer('exception inside transaction', (server) {
    late Connection conn;

    setUp(() async {
      conn = await server.newConnection();
      await conn.execute('CREATE TEMPORARY TABLE t (id INT UNIQUE)');
    });

    tearDown(() async {
      await conn.close();
    });

    test('exception thrown in transaction is propagated out', () async {
      final expectedException = Exception('my custom exception');
      dynamic actualException;
      dynamic thrownException;
      await conn.runTx((session) async {
        await session.execute('INSERT INTO t (id) VALUES (1)');
        try {
          await session.execute('INSERT INTO t (id) VALUES (1)');
        } on PgException catch (e) {
          thrownException = e;
          throw expectedException;
        }
      }).catchError((error) {
        actualException = error;
      });
      expect(actualException, expectedException);

      // testing the same exception without the try-catch block inside the transaction:
      dynamic uncaughtException;
      await conn.runTx((session) async {
        await session.execute('INSERT INTO t (id) VALUES (1)');
        await session.execute('INSERT INTO t (id) VALUES (1)');
      }).catchError((error) {
        uncaughtException = error;
      });
      expect(uncaughtException.toString(), thrownException.toString());
    });

    // TODO: decide if this is the desired outcome.
    test('exception caught in transaction is propagated out', () async {
      await expectLater(
        () => conn.runTx((c) async {
          await c.execute('INSERT INTO t (id) VALUES (1)');
          try {
            await c.execute('INSERT INTO t (id) VALUES (1)');
          } catch (_) {
            // ignore
          }
        }),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
