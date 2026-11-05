import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../support/docker.dart';

void main() {
  withPostgresServer('pool leaked transaction', (server) {
    var counter = 0;

    Future<(Pool, Connection, String)> open() async {
      final name = 'leak_${counter++}';
      final pool = Pool.withEndpoints([
        await server.endpoint(),
      ], settings: PoolSettings(applicationName: name, maxConnectionCount: 1));
      addTearDown(pool.close);
      final observer = await Connection.open(await server.endpoint());
      addTearDown(observer.close);
      return (pool, observer, name);
    }

    Future<int> idleInTransaction(Connection observer, String name) async {
      final r = await observer.execute(
        'SELECT count(*) FROM pg_stat_activity '
        r"WHERE application_name = $1 AND state LIKE 'idle in transaction%'",
        parameters: [name],
      );
      return r.single.single as int;
    }

    test('pool.execute rejects BEGIN and drops the connection', () async {
      final (pool, observer, name) = await open();
      await expectLater(
        pool.execute('BEGIN'),
        throwsA(
          isA<PgException>().having(
            (e) => e.message,
            'message',
            contains('transaction'),
          ),
        ),
      );
      // The transaction was not left open on a pooled connection.
      expect(await idleInTransaction(observer, name), 0);
      // The pool still works.
      expect((await pool.execute('SELECT 1')).single.single, 1);
    });

    test('withConnection dropping an open tx closes the connection', () async {
      final (pool, observer, name) = await open();
      await pool.withConnection((c) => c.execute('BEGIN'));
      expect(await idleInTransaction(observer, name), 0);
      expect((await pool.execute('SELECT 1')).single.single, 1);
    });

    test('runTx and withConnection with COMMIT are unaffected', () async {
      final (pool, observer, name) = await open();
      await pool.runTx((tx) => tx.execute('SELECT 1'));
      await pool.withConnection((c) async {
        await c.execute('BEGIN');
        await c.execute('SELECT 1');
        await c.execute('COMMIT');
      });
      expect(await idleInTransaction(observer, name), 0);
    });
  });
}
