import 'package:postgres/postgres.dart';
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('v3 close', (server) {
    late PgConnection conn1;
    late PgConnection conn2;

    setUp(() async {
      conn1 = await PgConnection.open(
        await server.endpoint(),
        sessionSettings: PgSessionSettings(
          onBadSslCertificate: (cert) => true,
          //transformer: _loggingTransformer('c1'),
        ),
      );

      conn2 = await PgConnection.open(
        await server.endpoint(),
        sessionSettings: PgSessionSettings(
          onBadSslCertificate: (cert) => true,
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
          final endpoint = await server.endpoint();
          final res = await conn2.execute(
              "SELECT pid FROM pg_stat_activity where usename = '${endpoint.username}';");
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
      final endpoint = await server.endpoint();
      // Get the PID for conn1
      final res = await conn2.execute(
          "SELECT pid FROM pg_stat_activity where usename = '${endpoint.username}';");
      final conn1PID = res.first.first as int;

      // ignore: unawaited_futures
      expect(
          conn1.execute('select pg_sleep(1) from pg_stat_activity;',
              ignoreRows: true),
          _throwsPostgresException);

      await conn2.execute(
          'select pg_terminate_backend($conn1PID) from pg_stat_activity;');
    });
  });
}

final _isPostgresException = isA<PostgreSQLException>();
final _throwsPostgresException = throwsA(_isPostgresException);
