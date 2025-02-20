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

    test('DuplicateKeyException', () async {
      final c = await server.newConnection();
      await c.execute('CREATE TABLE test (id INT PRIMARY KEY);');
      await c.execute('INSERT INTO test (id) VALUES (1);');
      addTearDown(() async => c.execute('DROP TABLE test;'));

      try {
        await c.execute('INSERT INTO test (id) VALUES (1);');
      } catch (e) {
        expect(e, isA<DuplicateKeyException>());
        expect(
            e.toString(),
            contains(
                'duplicate key value violates unique constraint "test_pkey"'));
      }
    });

    test('ForeignKeyViolationException', () async {
      final c = await server.newConnection();
      await c.execute('CREATE TABLE test (id INT PRIMARY KEY);');
      await c.execute(
          'CREATE TABLE test2 (id INT PRIMARY KEY, test_id INT REFERENCES test(id));');
      await c.execute('INSERT INTO test (id) VALUES (1);');
      addTearDown(() async {
        await c.execute('DROP TABLE test2;');
        await c.execute('DROP TABLE test;');
      });

      try {
        await c.execute('INSERT INTO test2 (id, test_id) VALUES (1, 2);');
      } catch (e) {
        expect(e, isA<ForeignKeyViolationException>());
        expect(
          e.toString(),
          contains(
            'insert or update on table "test2" violates foreign key constraint "test2_test_id_fkey"',
          ),
        );
      }
    });
  });
}
