import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  usePostgresDocker();
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

  test(
      'Timeout fires on query while in queue does not execute query, query throws exception',
      () async {
    //ignore: unawaited_futures
    final f = conn.query('SELECT pg_sleep(2)');
    try {
      await conn.query('SELECT 1', timeoutInSeconds: 1);
      fail('unreachable');
    } on TimeoutException {
      // ignore
    }

    expect(f, completes);
  });

  test('Timeout fires during transaction rolls ack transaction', () async {
    try {
      await conn.transaction((ctx) async {
        await ctx.query('INSERT INTO t (id) VALUES (1)');
        await ctx.query('SELECT pg_sleep(2)', timeoutInSeconds: 1);
      });
      fail('unreachable');
    } on TimeoutException {
      // ignore
    }

    expect(await conn.query('SELECT * from t'), hasLength(0));
  });

  test(
      'Query on parent context for transaction completes (with error) after timeout',
      () async {
    try {
      await conn.transaction((ctx) async {
        await conn.query('SELECT 1', timeoutInSeconds: 1);
        await ctx.query('INSERT INTO t (id) VALUES (1)');
      });
      fail('unreachable');
    } on TimeoutException {
      // ignore
    }

    expect(await conn.query('SELECT * from t'), hasLength(0));
  });

  test(
      'If query is already on the wire and times out, safely throws timeoutexception and nothing else',
      () async {
    try {
      await conn.query('SELECT pg_sleep(2)', timeoutInSeconds: 1);
      fail('unreachable');
    } on TimeoutException {
      // ignore
    }
  });

  test('Query times out, next query in the queue runs', () async {
    final rs = await conn.query('SELECT 1');
    //ignore: unawaited_futures
    conn.query('SELECT pg_sleep(2)', timeoutInSeconds: 1).catchError((_) => rs);

    expect(await conn.query('SELECT 1'), [
      [1]
    ]);
  });

  test('Query that succeeds does not timeout', () async {
    await conn.query('SELECT 1', timeoutInSeconds: 1);
    expect(Future.delayed(Duration(seconds: 2)), completes);
  });

  test('Query that fails does not timeout', () async {
    final rs = await conn.query('SELECT 1');
    await conn
        .query("INSERT INTO t (id) VALUES ('foo')", timeoutInSeconds: 1)
        .catchError((_) => rs);
    expect(Future.delayed(Duration(seconds: 2)), completes);
  });
}
