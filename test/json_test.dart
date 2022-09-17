import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  usePostgresDocker();
  late PostgreSQLConnection connection;

  setUp(() async {
    connection = PostgreSQLConnection('localhost', 5432, 'dart_test',
        username: 'dart', password: 'dart');
    await connection.open();

    await connection.execute('''
        CREATE TEMPORARY TABLE t (j jsonb)
    ''');
  });

  tearDown(() async {
    await connection.close();
  });

  group('Storage', () {
    test('Can store JSON String', () async {
      var result = await connection
          .query("INSERT INTO t (j) VALUES ('\"xyz\"'::jsonb) RETURNING j");
      expect(result, [
        ['xyz']
      ]);
      result = await connection.query('SELECT j FROM t');
      expect(result, [
        ['xyz']
      ]);
    });

    test('Can store JSON String with driver type annotation', () async {
      var result = await connection.query(
          'INSERT INTO t (j) VALUES (@a:jsonb) RETURNING j',
          substitutionValues: {'a': 'xyz'});
      expect(result, [
        ['xyz']
      ]);
      result = await connection.query('SELECT j FROM t');
      expect(result, [
        ['xyz']
      ]);
    });

    test('Can store JSON Number', () async {
      var result = await connection
          .query("INSERT INTO t (j) VALUES ('4'::jsonb) RETURNING j");
      expect(result, [
        [4]
      ]);
      result = await connection.query('SELECT j FROM t');
      expect(result, [
        [4]
      ]);
    });

    test('Can store JSON Number with driver type annotation', () async {
      var result = await connection.query(
          'INSERT INTO t (j) VALUES (@a:jsonb) RETURNING j',
          substitutionValues: {'a': 4});
      expect(result, [
        [4]
      ]);
      result = await connection.query('SELECT j FROM t');
      expect(result, [
        [4]
      ]);
    });

    test('Can store JSON map', () async {
      var result = await connection
          .query("INSERT INTO t (j) VALUES ('{\"a\":4}') RETURNING j");
      expect(result, [
        [
          {'a': 4}
        ]
      ]);
      result = await connection.query('SELECT j FROM t');
      expect(result, [
        [
          {'a': 4}
        ]
      ]);
    });

    test('Can store JSON map with driver type annotation', () async {
      var result = await connection.query(
          'INSERT INTO t (j) VALUES (@a:jsonb) RETURNING j',
          substitutionValues: {
            'a': {'a': 4}
          });
      expect(result, [
        [
          {'a': 4}
        ]
      ]);
      result = await connection.query('SELECT j FROM t');
      expect(result, [
        [
          {'a': 4}
        ]
      ]);
    });
    test('Can store JSON map with execute', () async {
      final result = await connection.execute(
          'INSERT INTO t (j) VALUES (@a:jsonb) RETURNING j',
          substitutionValues: {
            'a': {'a': 4}
          });
      expect(result, 1);
      final resultQuery = await connection.query('SELECT j FROM t');
      expect(resultQuery, [
        [
          {'a': 4}
        ]
      ]);
    });

    test('Can store JSON list', () async {
      var result = await connection
          .query("INSERT INTO t (j) VALUES ('[{\"a\":4}]') RETURNING j");
      expect(result, [
        [
          [
            {'a': 4}
          ]
        ]
      ]);
      result = await connection.query('SELECT j FROM t');
      expect(result, [
        [
          [
            {'a': 4}
          ]
        ]
      ]);
    });

    test('Can store JSON list with driver type annotation', () async {
      var result = await connection.query(
          'INSERT INTO t (j) VALUES (@a:jsonb) RETURNING j',
          substitutionValues: {
            'a': [
              {'a': 4}
            ]
          });
      expect(result, [
        [
          [
            {'a': 4}
          ]
        ]
      ]);
      result = await connection.query('SELECT j FROM t');
      expect(result, [
        [
          [
            {'a': 4}
          ]
        ]
      ]);
    });
  });
}
