import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('JSON storage', (server) {
    late Connection connection;

    setUp(() async {
      connection = await server.newConnection();

      await connection.execute('''
        CREATE TEMPORARY TABLE t (j jsonb)
    ''');
    });

    tearDown(() async {
      await connection.close();
    });

    test('Can store JSON String', () async {
      var result = await connection.execute(
        "INSERT INTO t (j) VALUES ('\"xyz\"'::jsonb) RETURNING j",
      );
      expect(result, [
        ['xyz'],
      ]);
      result = await connection.execute('SELECT j FROM t');
      expect(result, [
        ['xyz'],
      ]);
    });

    test('Can store JSON String with driver type annotation', () async {
      var result = await connection.execute(
        Sql.named('INSERT INTO t (j) VALUES (@a:jsonb) RETURNING j'),
        parameters: {'a': 'xyz'},
      );
      expect(result, [
        ['xyz'],
      ]);
      result = await connection.execute('SELECT j FROM t');
      expect(result, [
        ['xyz'],
      ]);
    });

    test('Can store JSON Number', () async {
      var result = await connection.execute(
        "INSERT INTO t (j) VALUES ('4'::jsonb) RETURNING j",
      );
      expect(result, [
        [4],
      ]);
      result = await connection.execute('SELECT j FROM t');
      expect(result, [
        [4],
      ]);
    });

    test('Can store JSON Number with driver type annotation', () async {
      var result = await connection.execute(
        Sql.named('INSERT INTO t (j) VALUES (@a:jsonb) RETURNING j'),
        parameters: {'a': 4},
      );
      expect(result, [
        [4],
      ]);
      result = await connection.execute('SELECT j FROM t');
      expect(result, [
        [4],
      ]);
    });

    test('Can store JSON map', () async {
      var result = await connection.execute(
        "INSERT INTO t (j) VALUES ('{\"a\":4}') RETURNING j",
      );
      expect(result, [
        [
          {'a': 4},
        ],
      ]);
      result = await connection.execute('SELECT j FROM t');
      expect(result, [
        [
          {'a': 4},
        ],
      ]);
    });

    test('Can store JSON map with driver type annotation', () async {
      var result = await connection.execute(
        Sql.named('INSERT INTO t (j) VALUES (@a:jsonb) RETURNING j'),
        parameters: {
          'a': {'a': 4},
        },
      );
      expect(result, [
        [
          {'a': 4},
        ],
      ]);
      result = await connection.execute('SELECT j FROM t');
      expect(result, [
        [
          {'a': 4},
        ],
      ]);
    });
    test('Can store JSON map with execute', () async {
      final result = await connection.execute(
        Sql.named('INSERT INTO t (j) VALUES (@a:jsonb) RETURNING j'),
        parameters: {
          'a': {'a': 4},
        },
      );
      expect(result, hasLength(1));
      final resultQuery = await connection.execute('SELECT j FROM t');
      expect(resultQuery, [
        [
          {'a': 4},
        ],
      ]);
    });

    test('Can store JSON list', () async {
      var result = await connection.execute(
        "INSERT INTO t (j) VALUES ('[{\"a\":4}]') RETURNING j",
      );
      expect(result, [
        [
          [
            {'a': 4},
          ],
        ],
      ]);
      result = await connection.execute('SELECT j FROM t');
      expect(result, [
        [
          [
            {'a': 4},
          ],
        ],
      ]);
    });

    test('Can store JSON list with driver type annotation', () async {
      var result = await connection.execute(
        Sql.named('INSERT INTO t (j) VALUES (@a:jsonb) RETURNING j'),
        parameters: {
          'a': [
            {'a': 4},
          ],
        },
      );
      expect(result, [
        [
          [
            {'a': 4},
          ],
        ],
      ]);
      result = await connection.execute('SELECT j FROM t');
      expect(result, [
        [
          [
            {'a': 4},
          ],
        ],
      ]);
    });
  });

  withPostgresServer('JSONB array with SQL NULLs', (server) {
    late Connection connection;

    setUp(() async {
      connection = await server.newConnection();
      await connection.execute(
        'CREATE TEMPORARY TABLE t (j jsonb[])',
      );
    });

    tearDown(() async {
      await connection.close();
    });

    test('Can store jsonb[] with SQL NULL elements via TypedValue', () async {
      final result = await connection.execute(
        Sql.named('INSERT INTO t (j) VALUES (@a) RETURNING j'),
        parameters: {
          'a': TypedValue(Type.jsonbArray, [
            TypedValue(Type.jsonb, null, isSqlNull: true), // SQL NULL element
            null, // 'null'::jsonb
            {'key': 'value'},
          ]),
        },
      );
      final row = result.single;
      final cell = row.single as List;
      expect(cell[0], isNull);
      expect(cell[1], isNull);
      expect(cell[2], {'key': 'value'});
    });
  });
}
