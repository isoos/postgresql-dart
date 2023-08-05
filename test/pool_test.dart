import 'dart:async';

import 'package:postgres/postgres_v3_experimental.dart';
import 'package:test/test.dart';

import 'docker.dart';

final _endpoint = PgEndpoint(
  host: 'localhost',
  database: 'dart_test',
  username: 'dart',
  password: 'dart',
);

void main() {
  usePostgresDocker();

  group('generic', () {
    late PgPool pool;

    setUp(() => pool = PgPool.open([_endpoint]));
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
          'CREATE TABLE IF NOT EXISTS transaction_test (bar INTEGER);');
      addTearDown(() => pool.execute('DROP TABLE transaction_test;'));

      final completeTransaction = Completer();
      final transaction = pool.runTx((session) async {
        await pool
            .execute('INSERT INTO transaction_test VALUES (1), (2), (3);');
        await completeTransaction.future;
      });

      var rows = await pool.execute('SELECT * FROM transaction_test');
      expect(rows, isEmpty);

      completeTransaction.complete();
      await transaction;

      rows = await pool.execute('SELECT * FROM transaction_test');
      expect(rows, hasLength(3));
    });

    test('can use prepared statements', () async {
      await pool
          .execute('CREATE TABLE IF NOT EXISTS statements_test (bar INTEGER);');
      addTearDown(() => pool.execute('DROP TABLE statements_test;'));

      final stmt = await pool.prepare('SELECT * FROM statements_test');
      expect(await stmt.run([]), isEmpty);

      await pool.execute('INSERT INTO statements_test VALUES (1), (2), (3);');

      expect(await stmt.run([]), hasLength(3));
      await stmt.dispose();
    });
  });

  test('can limit concurrent connections', () async {
    final pool = PgPool.open(
      [_endpoint],
      poolSettings: const PgPoolSettings(maxConnectionCount: 2),
    );
    addTearDown(pool.close);

    final wait = Completer();

    // Take two connections
    unawaited(pool.withConnection((connection) => wait.future));
    unawaited(pool.withConnection((connection) => wait.future));

    // Creating a third one should block.
    var didInvokeCallback = false;
    unawaited(pool.withConnection((connection) async {
      didInvokeCallback = true;
    }));

    await pumpEventQueue();
    expect(didInvokeCallback, isFalse);

    wait.complete();
    await pumpEventQueue();
    expect(didInvokeCallback, isTrue);
  });
}
