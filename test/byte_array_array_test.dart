import 'dart:typed_data';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('byteArrayArray (_bytea)', (server) {
    late Connection conn;

    setUp(() async {
      conn = await server.newConnection();
    });

    tearDown(() async {
      await conn.close();
    });

    test('round-trips via SELECT', () async {
      Future<void> check(List<List<int>?> value) async {
        final result = await conn.execute(
          Sql(r'SELECT $1', types: [Type.byteArrayArray]),
          parameters: [value],
        );
        final returned = result.single.single as List;
        expect(returned.length, value.length);
        for (var i = 0; i < value.length; i++) {
          if (value[i] == null) {
            expect(returned[i], isNull);
          } else {
            expect(returned[i], value[i]);
          }
        }
      }

      await check([]);
      await check([
        [0],
      ]);
      await check([
        [1, 2, 3],
      ]);
      await check([
        [255, 254, 253],
      ]);
      await check([
        [0],
        [1, 2, 3],
        [255, 254, 253],
      ]);
      await check([null]);
      await check([
        null,
        [1, 2, 3],
        null,
      ]);
    });

    test('round-trips via named parameter', () async {
      Future<void> check(List<List<int>?> value) async {
        final result = await conn.execute(
          Sql.named('SELECT @v:_bytea'),
          parameters: {'v': value},
        );
        final returned = result.single.single as List;
        expect(returned.length, value.length);
        for (var i = 0; i < value.length; i++) {
          if (value[i] == null) {
            expect(returned[i], isNull);
          } else {
            expect(returned[i], value[i]);
          }
        }
      }

      await check([]);
      await check([
        [42],
      ]);
      await check([
        null,
        [1, 2],
        [3, 4, 5],
      ]);
    });

    test('round-trips through a table column', () async {
      await conn.execute('CREATE TEMPORARY TABLE t (v bytea[])');

      final values = [
        <List<int>?>[],
        [
          [0],
        ],
        [
          [1, 2, 3],
          [255, 254, 253],
        ],
        [
          null,
          [10, 20],
          null,
        ],
      ];

      for (final value in values) {
        await conn.execute(
          Sql.named('INSERT INTO t (v) VALUES (@v:_bytea)'),
          parameters: {'v': value},
        );
      }

      final result = await conn.execute('SELECT v FROM t ORDER BY ctid');
      expect(result.length, values.length);

      for (var i = 0; i < values.length; i++) {
        final returned = result[i][0] as List;
        final expected = values[i];
        expect(returned.length, expected.length);
        for (var j = 0; j < expected.length; j++) {
          if (expected[j] == null) {
            expect(returned[j], isNull);
          } else {
            expect(returned[j], expected[j]);
          }
        }
      }
    });

    test('SQL NULL round-trips as null', () async {
      final result = await conn.execute(
        Sql.named('SELECT @v:_bytea'),
        parameters: {'v': null},
      );
      expect(result.single.single, isNull);
    });

    test('decoded elements are Uint8List', () async {
      final result = await conn.execute(
        Sql(r'SELECT $1', types: [Type.byteArrayArray]),
        parameters: [
          [
            [1, 2, 3],
          ],
        ],
      );
      final list = result.single.single as List;
      expect(list.single, isA<Uint8List>());
    });

    test('rejects wrong element type', () async {
      await expectLater(
        () => conn.execute(
          Sql.named('SELECT @v:_bytea'),
          parameters: {
            'v': ['not-a-list'],
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
