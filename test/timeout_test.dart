import 'dart:async';

import 'package:postgres/postgres.dart';
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

    test(
        'Timeout fires on query while in queue does not execute query, query throws exception',
        () async {
      //ignore: unawaited_futures
      final f = conn.execute('SELECT pg_sleep(2)');
      try {
        await conn.execute('SELECT 1', timeout: Duration(seconds: 1));
        fail('unreachable');
      } on TimeoutException {
        // ignore
      }

      expect(f, completes);
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

    test(
        'Query on parent context for transaction completes (with error) after timeout',
        () async {
      try {
        await conn.runTx((ctx) async {
          await conn.execute('SELECT 1', timeout: Duration(seconds: 1));
          await ctx.execute('INSERT INTO t (id) VALUES (1)');
        });
        fail('unreachable');
      } on TimeoutException {
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
      expect(Future.delayed(Duration(seconds: 2)), completes);
    });

    test('Query that fails does not timeout', () async {
      final rs = await conn.execute('SELECT 1');
      await conn
          .execute("INSERT INTO t (id) VALUES ('foo')",
              timeout: Duration(seconds: 1))
          .catchError((_) => rs);
      expect(Future.delayed(Duration(seconds: 2)), completes);
    });
  });
}
