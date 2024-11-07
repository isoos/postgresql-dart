import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('transaction isolations', (server) {
    late Connection conn1;
    late Connection conn2;

    setUp(() async {
      conn1 = await server.newConnection();
      conn2 = await server.newConnection();
      await conn1.execute('CREATE TABLE t (id INT PRIMARY KEY, counter INT)');
      await conn1.execute('INSERT INTO t VALUES (1, 0)');
    });

    tearDown(() async {
      await conn1.execute('DROP TABLE t;');
      await conn1.close();
      await conn2.close();
    });

    test('read committed works as expected', () async {
      final c1 = Completer();
      final c2 = Completer();
      final c3 = Completer();
      final f1 = Future.microtask(
        () => conn1.runTx(
          settings: TransactionSettings(
            isolationLevel: IsolationLevel.readCommitted,
          ),
          (session) async {
            await c2.future;
            await session
                .execute('UPDATE t SET counter = counter + 1 WHERE id=1');
            c1.complete();
            // await c3.future;
          },
        ),
      );
      final f2 = Future.microtask(
        () => conn2.runTx(
          settings: TransactionSettings(
            isolationLevel: IsolationLevel.readCommitted,
          ),
          (session) async {
            c2.complete();
            await c1.future;
            await session
                .execute('UPDATE t SET counter = counter + 1 WHERE id=1');
            c3.complete();
          },
        ),
      );
      await Future.wait([f1, f2]);
      final rs = await conn1.execute('SELECT * from t WHERE id=1');
      expect(rs.single, [1, 2]);
    });

    test('forced serialization failure', () async {
      final c1 = Completer();
      final c2 = Completer();
      final c3 = Completer();
      final f1 = Future.microtask(
        () => conn1.runTx(
          settings: TransactionSettings(
            isolationLevel: IsolationLevel.serializable,
          ),
          (session) async {
            await c2.future;
            await session
                .execute('UPDATE t SET counter = counter + 1 WHERE id=1');
            c1.complete();
            // await c3.future;
          },
        ),
      );
      final f2 = Future.microtask(
        () => conn2.runTx(
          settings: TransactionSettings(
            isolationLevel: IsolationLevel.serializable,
          ),
          (session) async {
            c2.complete();
            await c1.future;
            await session
                .execute('UPDATE t SET counter = counter + 1 WHERE id=1');
            c3.complete();
          },
        ),
      );
      await expectLater(
          () => Future.wait([f1, f2]), throwsA(isA<ServerException>()));
      final rs = await conn1.execute('SELECT * from t WHERE id=1');
      expect(rs.single, [1, 1]);
    });
  });

  withPostgresServer('Transaction isolation level', (server) {
    group('Given two rows in the database and two database connections', () {
      late Connection conn1;
      late Connection conn2;
      setUp(() async {
        conn1 = await server.newConnection();
        conn2 = await server.newConnection();
        await conn1.execute('CREATE TABLE t (id INT PRIMARY KEY, counter INT)');
        await conn1.execute('INSERT INTO t VALUES (1, 0)');
        await conn1.execute('INSERT INTO t VALUES (2, 1)');
      });

      tearDown(() async {
        await conn1.execute('DROP TABLE t;');
        await conn1.close();
        await conn2.close();
      });

      test(
          'when two transactions using repeatable read isolation level'
          'reads the row updated by the other transaction'
          'then one transaction throws exception ', () async {
        final c1 = Completer();
        final c2 = Completer();
        final f1 = Future.microtask(
          () => conn1.runTx(
            settings: TransactionSettings(
              isolationLevel: IsolationLevel.serializable,
            ),
            (session) async {
              await session.execute('SELECT * from t WHERE id=1');

              c1.complete();
              await c2.future;

              await session
                  .execute('UPDATE t SET counter = counter + 10 WHERE id=2');
            },
          ),
        );
        final f2 = Future.microtask(
          () => conn2.runTx(
            settings: TransactionSettings(
              isolationLevel: IsolationLevel.serializable,
            ),
            (session) async {
              await session.execute('SELECT * from t WHERE id=2');

              await c1.future;
              // If we complete both transactions in parallel, we get an unexpected
              // exception
              c2.complete();

              await session
                  .execute('UPDATE t SET counter = counter + 20 WHERE id=1');
              // If we complete the first transaction after the second transaction
              // the correct exception is thrown
              // c2.complete();
            },
          ),
        );

        // This test throws Severity.error Session or transaction has already
        // finished, did you forget to await a statement?
        await expectLater(
          () => Future.wait([f1, f2]),
          throwsA(
            isA<ServerException>()
                .having((e) => e.severity, 'Exception severity', Severity.error)
                .having((e) => e.code, 'Exception code', '40001'),
          ),
        );
      });
    });
  });
}
