import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../support/docker.dart';

void main() {
  withPostgresServer('pool session reset', (server) {
    Future<Pool> open({bool? resetSession}) async => Pool.withEndpoints(
      [await server.endpoint()],
      settings: PoolSettings(
        maxConnectionCount: 1,
        resetSession: resetSession,
        onOpen: (c) => c.execute("SET application_name = 'from_on_open'"),
      ),
    );

    Future<String> appName(Pool pool) async =>
        (await pool.execute('SHOW application_name')).single.single as String;

    test('SET does not leak to the next user', () async {
      final pool = await open();
      addTearDown(pool.close);
      await pool.execute("SET application_name = 'leaked'");
      // onOpen value is restored, not the leaked one.
      expect(await appName(pool), 'from_on_open');
    });

    test('temp tables do not leak', () async {
      final pool = await open();
      addTearDown(pool.close);
      await pool.execute('CREATE TEMP TABLE t_reset (a int)');
      await expectLater(
        pool.execute('SELECT * FROM t_reset'),
        throwsA(isA<PgException>()),
      );
    });

    test('clean connection is reused without reset', () async {
      final pool = await open();
      addTearDown(pool.close);
      final pid1 = (await pool.execute('SELECT pg_backend_pid()')).single[0];
      final pid2 = (await pool.execute('SELECT pg_backend_pid()')).single[0];
      expect(pid2, pid1);
    });

    test('session advisory lock is released on return', () async {
      final pool = await open();
      addTearDown(pool.close);
      final other = await Connection.open(await server.endpoint());
      addTearDown(other.close);
      await pool.execute('SELECT pg_advisory_lock(4242)');
      // No other use of the pool: the lock must already be gone.
      final got = await other.execute('SELECT pg_try_advisory_lock(4242)');
      expect(got.single.single, true);
    });

    test('other state is reset lazily on reuse, not on return', () async {
      final pool = await open();
      addTearDown(pool.close);
      final pid = (await pool.execute('SELECT pg_backend_pid()')).single[0];
      await pool.execute("SET application_name = 'leaked'");
      final other = await Connection.open(await server.endpoint());
      addTearDown(other.close);
      // Idle connection still carries the setting (not reset yet).
      final idle = await other.execute(
        r'SELECT application_name FROM pg_stat_activity WHERE pid = $1',
        parameters: [pid],
      );
      expect(idle.single.single, 'leaked');
      // Reuse resets it, on the same backend.
      expect(await appName(pool), 'from_on_open');
      expect((await pool.execute('SELECT pg_backend_pid()')).single[0], pid);
    });

    test('can be disabled', () async {
      final pool = await open(resetSession: false);
      addTearDown(pool.close);
      await pool.execute("SET application_name = 'leaked'");
      expect(await appName(pool), 'leaked');
    });

    group('idle check', () {
      Future<Pool> openIdle(Duration? idleCheckAfter) async =>
          Pool.withEndpoints(
            [await server.endpoint()],
            settings: PoolSettings(
              maxConnectionCount: 1,
              idleCheckAfter: idleCheckAfter,
            ),
          );

      test('idle connection that is still alive is reused', () async {
        final pool = await openIdle(Duration(milliseconds: 1));
        addTearDown(pool.close);
        final pid = (await pool.execute('SELECT pg_backend_pid()')).single[0];
        await Future.delayed(Duration(milliseconds: 20));
        expect((await pool.execute('SELECT pg_backend_pid()')).single[0], pid);
      });

      test('terminated idle connection is replaced', () async {
        final pool = await openIdle(Duration(milliseconds: 1));
        addTearDown(pool.close);
        final pid = (await pool.execute('SELECT pg_backend_pid()')).single[0];
        final other = await Connection.open(await server.endpoint());
        addTearDown(other.close);
        await other.execute('SELECT pg_terminate_backend($pid)');
        await Future.delayed(Duration(milliseconds: 50));
        final next = (await pool.execute('SELECT pg_backend_pid()')).single[0];
        expect(next, isNot(pid));
      });

      test('can be disabled', () async {
        final pool = await openIdle(Duration.zero);
        addTearDown(pool.close);
        final pid = (await pool.execute('SELECT pg_backend_pid()')).single[0];
        await Future.delayed(Duration(milliseconds: 20));
        expect((await pool.execute('SELECT pg_backend_pid()')).single[0], pid);
      });
    });
  });
}
