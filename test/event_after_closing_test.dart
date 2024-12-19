import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void _print(x) {
  // uncomment to debug locally
  // print(x);
}

void main() {
  withPostgresServer('event after closing', (server) {
    Future<void> createTableAndPopulate(Connection conn) async {
      final sw = Stopwatch()..start();

      await conn.execute('''
    CREATE TABLE IF NOT EXISTS large_table (
      id SERIAL PRIMARY KEY,
      c1 INTEGER NOT NULL,
      c2 INTEGER NOT NULL,
      c3 TEXT NOT NULL,
      c4 TEXT NOT NULL,
      c5 TEXT NOT NULL,
      c6 TEXT NOT NULL,
      c7 TEXT NOT NULL,
      c8 TEXT NOT NULL,
      c9 TEXT NOT NULL,
      c10 TEXT NOT NULL
    )
  ''');

      final numBatches = 20;
      final batchSize = 5000;

      for (var i = 0; i < numBatches; i++) {
        _print('Batch $i of $numBatches');
        final values = List.generate(
            batchSize,
            (i) => [
                  i,
                  i * 2,
                  'value $i',
                  'value $i',
                  'value $i',
                  'value $i',
                  'value $i',
                  'value $i',
                  'value $i',
                  'value $i',
                ]);

        final allArgs = values.expand((e) => e).toList();
        final valuesPart = List.generate(
                batchSize,
                (i) =>
                    '(${List.generate(10, (j) => '\$${i * 10 + j + 1}').join(', ')})')
            .join(', ');

        final stmt =
            'INSERT INTO large_table (c1, c2, c3, c4, c5, c6, c7, c8, c9, c10) VALUES $valuesPart';
        await conn.execute(
          stmt,
          parameters: allArgs,
        );
      }

      _print('Inserted ${numBatches * batchSize} rows in ${sw.elapsed}');
    }

    test('issue#398', () async {
      final conn = await server.newConnection();
      await createTableAndPopulate(conn);

      final rows = await conn.execute('SELECT * FROM large_table');
      _print('SELECTED ROWS ${rows.length}');

      await conn.close();
    });
  });
}
