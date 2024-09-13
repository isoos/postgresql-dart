import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:postgres/src/v3/connection.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('timeout', (server) {
    late Connection conn;

    setUp(() async {
      conn = await server.newConnection();
      await conn.execute('CREATE TEMPORARY TABLE t (id INT UNIQUE)');
    });

    tearDown(() async {
      await conn.close();
    });

    test('Cancel current statement through a new connection', () async {
      final f = conn.execute('SELECT pg_sleep(2);');
      await (conn as PgConnectionImplementation).cancelPendingStatement();
      await expectLater(f, throwsA(isA<ServerException>()));
      // connection is still usable
      final rs = await conn.execute('SELECT 1;');
      expect(rs[0][0], 1);
    });

    test('Timeout fires during transaction rolls ack transaction', () async {
      try {
        await conn.runTx((ctx) async {
          await ctx.execute('INSERT INTO t (id) VALUES (1)');
          await ctx.execute('SELECT pg_sleep(2)',
              timeout: Duration(seconds: 1));
        });
        fail('unreachable');
      } on TimeoutException {
        // ignore
      }

      expect(await conn.execute('SELECT * from t'), hasLength(0));
    });

    test('Timeout is ignored when new statement is run on parent context',
        () async {
      try {
        await conn.runTx((ctx) async {
          await conn.execute('SELECT 1', timeout: Duration(seconds: 1));
          await ctx.execute('INSERT INTO t (id) VALUES (1)');
        });
        fail('unreachable');
      } on PgException catch (e) {
        expect(e.message, contains('runTx'));
        // ignore
      }

      expect(await conn.execute('SELECT * from t'), hasLength(0));
    });

    test(
        'If query is already on the wire and times out, safely throws timeoutexception and nothing else',
        () async {
      try {
        await conn.execute('SELECT pg_sleep(2)', timeout: Duration(seconds: 1));
        fail('unreachable');
      } on TimeoutException {
        // ignore
      }
    });

    test('Query times out, next query in the queue runs', () async {
      final rs = await conn.execute('SELECT 1');
      //ignore: unawaited_futures
      conn
          .execute('SELECT pg_sleep(2)', timeout: Duration(seconds: 1))
          .catchError((_) => rs);

      expect(await conn.execute('SELECT 1'), [
        [1]
      ]);
    });

    test('Query that succeeds does not timeout', () async {
      await conn.execute('SELECT 1', timeout: Duration(seconds: 1));
    });

    test('Query that fails does not timeout', () async {
      final rs = await conn.execute('SELECT 1');
      Exception? caught;
      await conn
          .execute("INSERT INTO t (id) VALUES ('foo')",
              timeout: Duration(seconds: 1))
          .catchError((e) {
        caught = e;
        // needs this to match return type
        return rs;
      });
      expect(caught, isA<ServerException>());
    });
  });

  // Note: to fix this, we may consider cancelling the currently running statements:
  //       https://www.postgresql.org/docs/current/protocol-flow.html#PROTOCOL-FLOW-CANCELING-REQUESTS
  withPostgresServer('timeout race conditions', (server) {
    setUp(() async {
      final c1 = await server.newConnection();
      await c1.execute('CREATE TABLE t (id INT PRIMARY KEY);');
      await c1.execute('INSERT INTO t (id) values (1);');
    });

    test('two transactions for update', () async {
      for (final qm in QueryMode.values) {
        final c1 = await server.newConnection();
        final c2 = await server.newConnection(queryMode: qm);
        await c1.execute('BEGIN');
        await c1.execute('SELECT * FROM t WHERE id=1 FOR UPDATE');
        await c2.execute('BEGIN');
        try {
          await c2.execute('SELECT * FROM t WHERE id=1 FOR UPDATE',
              timeout: Duration(seconds: 1));
          fail('unreachable');
        } on TimeoutException catch (_) {
          // ignore
        }
        await c1.execute('ROLLBACK');
        await c2.execute('ROLLBACK');

        await c1.execute('SELECT 1');
        await c2.execute('SELECT 1');
      }
    });
  });
}
