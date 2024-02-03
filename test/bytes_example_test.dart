import 'dart:typed_data';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('bytes example', (server) {
    test('write and read', () async {
      final conn = await server.newConnection();
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS images (
        id SERIAL PRIMARY KEY,
        name TEXT,
        description TEXT,
        image BYTEA NOT NULL
        );
''');

      final rs1 = await conn.execute(Sql.named('''
        INSERT INTO images (name, description, image)
        VALUES (@name, @description, @image:bytea)
        RETURNING id
'''), parameters: {
        'name': 'name-1',
        'description': 'descr-1',
        'image': Uint8List.fromList([0, 1, 2]),
      });
      final id = rs1.single.single;

      final rs2 = await conn
          .execute(r'SELECT image FROM images WHERE id=$1', parameters: [id]);
      final bytes = rs2.single.single;
      expect(bytes, [0, 1, 2]);
    });
  });
}
