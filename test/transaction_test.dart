import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'dart:io';
import 'dart:async';
import 'dart:mirrors';

void main() {
  group("Transaction behavior", () {
    PostgreSQLConnection conn = null;

    setUp(() async {
      conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");
      await conn.open();
      await conn.execute("CREATE TEMPORARY TABLE t (id INT UNIQUE)");
    });

    tearDown(() async {
      await conn?.close();
    });

    test("Send successful transaction succeeds, returns returned value", () async {
      var outResult = await conn.transaction((c) async {
        await c.query("INSERT INTO t (id) VALUES (1)");

        return await c.query("SELECT id FROM t");
      });
      expect(outResult, [[1]]);

      var result = await conn.query("SELECT id FROM t");
      expect(result, [[1]]);
    });

    test("Query during transaction must wait until transaction is finished", () async {
      var orderEnsurer = [];
      var nextCompleter = new Completer.sync();
      var outResult = conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query("INSERT INTO t (id) VALUES (1)");
        orderEnsurer.add(2);
        nextCompleter.complete();
        var result = await c.query("SELECT id FROM t");
        orderEnsurer.add(3);

        return result;
      });

      await nextCompleter.future;
      orderEnsurer.add(11);
      await conn.query("INSERT INTO t (id) VALUES (2)");
      orderEnsurer.add(12);
      var laterResults = await conn.query("SELECT id FROM t");
      orderEnsurer.add(13);

      var firstResult = await outResult;

      expect(orderEnsurer, [1, 2, 11, 3, 12, 13]);
      expect(firstResult, [[1]]);
      expect(laterResults, [[1],[2]]);
    });

    test("Make sure two simultaneous transactions cannot be interwoven", () async {
      var orderEnsurer = [];

      var firstTransactionFuture = conn.transaction((c) async {
        orderEnsurer.add(11);
        await c.query("INSERT INTO t (id) VALUES (1)");
        orderEnsurer.add(12);
        var result = await c.query("SELECT id FROM t");
        orderEnsurer.add(13);

        return result;
      });

      var secondTransactionFuture = conn.transaction((c) async {
        orderEnsurer.add(21);
        await c.query("INSERT INTO t (id) VALUES (2)");
        orderEnsurer.add(22);
        var result = await c.query("SELECT id FROM t");
        orderEnsurer.add(23);

        return result;
      });

      var firstResults = await firstTransactionFuture;
      var secondResults = await secondTransactionFuture;

      expect(orderEnsurer, [11, 12, 13, 21, 22, 23]);

      expect(firstResults, [[1]]);
      expect(secondResults, [[1], [2]]);
    });

    test("May intentionally rollback transaction", () async {
      await conn.transaction((c) async {
        await c.query("INSERT INTO t (id) VALUES (1)");
        c.cancelTransaction();

        await c.query("INSERT INTO t (id) VALUES (2)");
      });

      var result = await conn.query("SELECT id FROM t");
      expect(result, []);
    });

    test("Intentional rollback on non-transaction has no impact", () async {
      conn.cancelTransaction();
      var result = await conn.query("SELECT id FROM t");
      expect(result, []);
    });

    test("Intentional rollback from outside of a transaction has no impact", () async {
      var orderEnsurer = [];
      var nextCompleter = new Completer.sync();
      var outResult = conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query("INSERT INTO t (id) VALUES (1)");
        orderEnsurer.add(2);
        nextCompleter.complete();
        var result = await c.query("SELECT id FROM t");
        orderEnsurer.add(3);

        return result;
      });

      await nextCompleter.future;
      conn.cancelTransaction();

      orderEnsurer.add(11);
      var results = await outResult;

      expect(orderEnsurer, [1, 2, 11, 3]);
      expect(results, [[1]]);
    });

    test("A transaction does not preempt pending queries", () async {
      // Add a few insert queries but don't await, then do a transaction that does a fetch,
      // make sure that transaction contains all of the elements.
      fail("NYI");
    });

    test("A transaction doesn't have to await on queries", () async {
      fail("NYI");
    });

    test("A transaction doesn't have to await on cancel", () async {
      fail("NYI");
    });

  });

  // A transaction can fail for three reasons: query error, exception in code, or a rollback.
  // After a transaction fails, the changes must be rolled back, it should continue with pending queries, pending transactions, later queries, later transactions

  group("Transaction:Query recovery", () {
    PostgreSQLConnection conn = null;

    setUp(() async {
      conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");
      await conn.open();
      await conn.execute("CREATE TEMPORARY TABLE t (id INT UNIQUE)");
    });

    tearDown(() async {
      await conn?.close();
    });

    test("Is rolled back/executes later query", () async {
      try {
        await conn.transaction((c) async {
          await c.query("INSERT INTO t (id) VALUES (1)");
          var oneRow = await c.query("SELECT id FROM t");
          expect(oneRow, [[1]]);

          // This will error
          await c.query("INSERT INTO t (id) VALUES (1)");
        });
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.message, contains("unique constraint"));
      }

      var noRows = await conn.query("SELECT id FROM t");
      expect(noRows, []);
    });

    test("Executes pending query", () async {
      var orderEnsurer = [];

      conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query("INSERT INTO t (id) VALUES (1)");
        orderEnsurer.add(2);

        // This will error
        await c.query("INSERT INTO t (id) VALUES (1)");
      }).catchError((e) => null);

      orderEnsurer.add(11);
      var result = await conn.query("SELECT id FROM t");
      orderEnsurer.add(12);

      expect(orderEnsurer, [11, 1, 2, 12]);
      expect(result, []);
    });

    test("Executes pending transaction", () async {
      var orderEnsurer = [];

      conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query("INSERT INTO t (id) VALUES (1)");
        orderEnsurer.add(2);

        // This will error
        await c.query("INSERT INTO t (id) VALUES (1)");
      }).catchError((e) => null);

      var result = await conn.transaction((ctx) async {
        orderEnsurer.add(11);
        return await ctx.query("SELECT id FROM t");
      });
      orderEnsurer.add(12);

      expect(orderEnsurer, [1, 2, 11, 12]);
      expect(result, []);
    });

    test("Executes later transaction", () async {
      try {
        await conn.transaction((c) async {
          await c.query("INSERT INTO t (id) VALUES (1)");
          var oneRow = await c.query("SELECT id FROM t");
          expect(oneRow, [[1]]);

          // This will error
          await c.query("INSERT INTO t (id) VALUES (1)");
        });
        expect(true, false);
      } on PostgreSQLException catch (e) {}

      var result = await conn.transaction((ctx) async {
        return await ctx.query("SELECT id FROM t");
      });
      expect(result, []);
    });
  });

  group("Transaction:Exception recovery", () {
    PostgreSQLConnection conn = null;

    setUp(() async {
      conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");
      await conn.open();
      await conn.execute("CREATE TEMPORARY TABLE t (id INT UNIQUE)");
    });

    tearDown(() async {
      await conn?.close();
    });

    test("Is rolled back/executes later query", () async {
      try {
        await conn.transaction((c) async {
          await c.query("INSERT INTO t (id) VALUES (1)");
          throw 'foo';
        });
        expect(true, false);
      } on String {}

      var noRows = await conn.query("SELECT id FROM t");
      expect(noRows, []);
    });

    test("Executes pending query", () async {
      var orderEnsurer = [];

      conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query("INSERT INTO t (id) VALUES (1)");
        orderEnsurer.add(2);
        throw 'foo';
      }).catchError((e) => null);

      orderEnsurer.add(11);
      var result = await conn.query("SELECT id FROM t");
      orderEnsurer.add(12);

      expect(orderEnsurer, [11, 1, 2, 12]);
      expect(result, []);
    });

    test("Executes pending transaction", () async {
      var orderEnsurer = [];

      conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query("INSERT INTO t (id) VALUES (1)");
        orderEnsurer.add(2);
        throw 'foo';
      }).catchError((e) => null);

      var result = await conn.transaction((ctx) async {
        orderEnsurer.add(11);
        return await ctx.query("SELECT id FROM t");
      });
      orderEnsurer.add(12);

      expect(orderEnsurer, [1, 2, 11, 12]);
      expect(result, []);
    });

    test("Executes later transaction", () async {
      try {
        await conn.transaction((c) async {
          await c.query("INSERT INTO t (id) VALUES (1)");
          throw 'foo';
        });
        expect(true, false);
      } on String {}

      var result = await conn.transaction((ctx) async {
        return await ctx.query("SELECT id FROM t");
      });
      expect(result, []);
    });
  });

  group("Transaction:Rollback recovery", () {
    PostgreSQLConnection conn = null;

    setUp(() async {
      conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");
      await conn.open();
      await conn.execute("CREATE TEMPORARY TABLE t (id INT UNIQUE)");
    });

    tearDown(() async {
      await conn?.close();
    });

    test("Is rolled back/executes later query", () async {
      var result = await conn.transaction((c) async {
        await c.query("INSERT INTO t (id) VALUES (1)");
        c.cancelTransaction();
        await c.query("INSERT INTO t (id) VALUES (2)");
      });

      expect(result is PostgreSQLRollback, true);

      var noRows = await conn.query("SELECT id FROM t");
      expect(noRows, []);
    });

    test("Executes pending query", () async {
      var orderEnsurer = [];

      conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query("INSERT INTO t (id) VALUES (1)");
        orderEnsurer.add(2);
        await c.cancelTransaction();
        await c.query("INSERT INTO t (id) VALUES (2)");
      });

      orderEnsurer.add(11);
      var result = await conn.query("SELECT id FROM t");
      orderEnsurer.add(12);

      expect(orderEnsurer, [11, 1, 2, 12]);
      expect(result, []);
    });

    test("Executes pending transaction", () async {
      var orderEnsurer = [];

      conn.transaction((c) async {
        orderEnsurer.add(1);
        await c.query("INSERT INTO t (id) VALUES (1)");
        orderEnsurer.add(2);
        await c.cancelTransaction();
        await c.query("INSERT INTO t (id) VALUES (2)");
        orderEnsurer.add(3);
      });

      var result = await conn.transaction((ctx) async {
        orderEnsurer.add(11);
        return await ctx.query("SELECT id FROM t");
      });
      orderEnsurer.add(12);

      expect(orderEnsurer, [1, 2, 11, 12]);
      expect(result, []);
    });

    test("Executes later transaction", () async {
      var result = await conn.transaction((c) async {
        await c.query("INSERT INTO t (id) VALUES (1)");
        c.cancelTransaction();
        await c.query("INSERT INTO t (id) VALUES (2)");
      });
      expect(result is PostgreSQLRollback, true);

      result = await conn.transaction((ctx) async {
        return await ctx.query("SELECT id FROM t");
      });
      expect(result, []);
    });
  });
}