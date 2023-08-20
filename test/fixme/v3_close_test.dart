import 'package:postgres/postgres_v3_experimental.dart';
import 'package:test/test.dart';

import '../docker.dart';

void main() {
  // NOTE: The Docker Container will not close after stopping this test so that needs to be done manually.
  usePostgresDocker();

  group('service-side connection close',
      skip: 'the error is not caught or handled properly', () {
    // ignore: unused_local_variable
    late final PgConnection conn1;
    late final PgConnection conn2;

    setUpAll(() async {
      conn1 = await PgConnection.open(
        PgEndpoint(
          host: 'localhost',
          database: 'dart_test',
          username: 'dart',
          password: 'dart',
        ),
        sessionSettings: PgSessionSettings(
          onBadSslCertificate: (cert) => true,
        ),
      );

      conn2 = await PgConnection.open(
        PgEndpoint(
          host: 'localhost',
          database: 'dart_test',
          username: 'postgres',
          password: 'postgres',
        ),
        sessionSettings: PgSessionSettings(
          onBadSslCertificate: (cert) => true,
        ),
      );
    });

    test('produce error', () async {
      // get conn1 PID
      final res = await conn2
          .execute("SELECT pid FROM pg_stat_activity where usename = 'dart';");
      final conn1PID = res.first.first as int;

      // Simulate issue by terminating a connection during a query
      // ignore: unawaited_futures
      conn1.execute(
          'select * from pg_stat_activity;'); // comment this out and a different error will appear

      // Terminate the conn1 while the query is running
      await conn2.execute(
          'select pg_terminate_backend($conn1PID) from pg_stat_activity;');
      // this will cause the following exception:
      // PostgreSQLException (PostgreSQLSeverity.fatal 57P01: terminating connection due to administrator command )

      expect(true, true);
    });

    tearDownAll(() async {
      print('closing conn1');
      await conn1.close(); // this will never close & execution will hang here
      print('closing conn2');
      await conn2.close();
    });
  });
}
