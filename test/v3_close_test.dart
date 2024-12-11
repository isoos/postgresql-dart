import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('v3 close', (server) {
    late Connection conn1;
    late Connection conn2;

    const conn1Name = 'conn1';
    const conn2Name = 'conn2';

    setUp(() async {
      conn1 = await Connection.open(
        await server.endpoint(),
        settings: ConnectionSettings(
          applicationName: conn1Name,
          //transformer: _loggingTransformer('c1'),
        ),
      );

      conn2 = await Connection.open(
        await server.endpoint(),
        settings: ConnectionSettings(
          applicationName: conn2Name,
        ),
      );
    });

    tearDown(() async {
      await conn1.close();
      await conn2.close();
    });

    for (final concurrentQuery in [false, true]) {
      test(
        'with concurrent query: $concurrentQuery',
        () async {
          final res = await conn2.execute(
              "SELECT pid FROM pg_stat_activity where application_name = '$conn1Name';");
          final conn1PID = res.first.first as int;

          // Simulate issue by terminating a connection during a query
          if (concurrentQuery) {
            // We expect that terminating the connection will throw.
            expect(conn1.execute('select pg_sleep(1) from pg_stat_activity;'),
                _throwsPostgresException);
          }

          // Terminate the conn1 while the query is running
          await conn2.execute('select pg_terminate_backend($conn1PID);');
        },
      );
    }

    test('with simple query protocol', () async {
      // Get the PID for conn1
      final res = await conn2.execute(
          "SELECT pid FROM pg_stat_activity where application_name = '$conn1Name';");
      final conn1PID = res.first.first as int;

      // ignore: unawaited_futures
      expect(
          conn1.execute('select pg_sleep(1) from pg_stat_activity;',
              ignoreRows: true),
          _throwsPostgresException);

      await conn2.execute(
          'select pg_terminate_backend($conn1PID) from pg_stat_activity;');
    });

    group('force close', () {
      Future<void> expectConn1ClosesForcefully() async {
        await conn1
            .close(force: true) //
            // If close takes too long, the test will fail (force=true would not be working correctly)
            // as it would be waiting for the query to finish
            .timeout(Duration(seconds: 1));
        expect(conn1.isOpen, isFalse);
      }

      Future<void> runLongQuery(Session session) {
        return session.execute('select pg_sleep(10) from pg_stat_activity;');
      }

      test('connection session', () async {
        // ignore: unawaited_futures
        runLongQuery(conn1);
        // let it start
        await Future.delayed(const Duration(milliseconds: 100));
        await expectConn1ClosesForcefully();
      });

      test('tx session', () async {
        // ignore: unawaited_futures
        // Ignore async error, it will fail when the connection is closed and it tries to do COMMIT
        conn1.runTx(runLongQuery).ignore();
        // let it start
        await Future.delayed(const Duration(milliseconds: 100));
        await expectConn1ClosesForcefully();
      });

      test('run session', () async {
        // ignore: unawaited_futures
        conn1.run(runLongQuery);
        // let it start
        await Future.delayed(const Duration(milliseconds: 100));
        await expectConn1ClosesForcefully();
      });
    });
  });
}

final _isPostgresException = isA<PgException>();
final _throwsPostgresException = throwsA(_isPostgresException);
