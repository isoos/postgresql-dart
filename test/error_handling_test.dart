import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('error handling', (server) {
    test('Reports stacktrace correctly', () async {
      final conn = await server.newConnection();
      addTearDown(() async => conn.close());

      // Root connection query
      try {
        await conn.execute('SELECT hello');
        fail('Should not reach');
      } catch (e, st) {
        expect(e.toString(), contains('column "hello" does not exist'));
        expect(
          st.toString(),
          contains('test/error_handling_test.dart'),
        );
      }

      // Root connection execute
      try {
        await conn.execute('DELETE FROM hello');
        fail('Should not reach');
      } catch (e, st) {
        expect(e.toString(), contains('relation "hello" does not exist'));
        expect(
          st.toString(),
          contains('test/error_handling_test.dart'),
        );
      }

      // Inside transaction
      try {
        await conn.runTx((s) async {
          await s.execute('SELECT hello');
          fail('Should not reach');
        });
      } catch (e, st) {
        expect(e.toString(), contains('column "hello" does not exist'));
        expect(
          st.toString(),
          contains('test/error_handling_test.dart'),
        );
      }
    });

    test('TimeoutException', () async {
      final c = await server.newConnection(queryMode: QueryMode.simple);
      await c.execute('SET statement_timeout = 1000;');
      await expectLater(
        () => c.execute('SELECT pg_sleep(2);'),
        throwsA(
          allOf(
            isA<TimeoutException>(),
            isA<PgException>().having(
              (e) => e.toString(),
              'toString()',
              'Severity.error 57014: canceling statement due to statement timeout',
            ),
          ),
        ),
      );
    });
  });
}
