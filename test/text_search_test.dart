import 'package:postgres/src/types/text_search.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('tsvector', (server) {
    test('decode output', () async {
      final c = await server.newConnection();
      final rs = await c.execute('SELECT \'x:11,12 yy:2A,4C\'::tsvector');
      final vector = rs.first.first as TsVector;
      expect(vector.lexemes, hasLength(2));
      expect(vector.lexemes.first.text, 'x');
      expect(vector.lexemes.first.toString(), 'x:11,12');
      expect(vector.lexemes.last.text, 'yy');
      expect(
        vector.lexemes.last.positions?.map((e) => e.toString()).toList(),
        ['2A', '4C'],
      );
    });

    test('encode and decode', () async {
      final c = await server.newConnection();
      final rs = await c.execute(r'SELECT $1::tsvector', parameters: [
        TsVector(lexemes: [
          Lexeme('ab'),
          Lexeme('cd', positions: [LexemePos(4, weight: LexemeWeight.c)]),
        ])
      ]);
      final first = rs.first.first as TsVector;
      expect(first.lexemes, hasLength(2));
      expect(first.lexemes.first.text, 'ab');
      expect(first.lexemes.first.positions, isNull);
      expect(first.lexemes.last.text, 'cd');
      expect(first.lexemes.last.positions?.single.toString(), '4C');
    });

    test('store and read', () async {
      final c = await server.newConnection();
      await c
          .execute('CREATE TABLE t (id TEXT, tsv TSVECTOR, PRIMARY KEY (id))');
      await c.execute(
        r'INSERT INTO t VALUES ($1, $2)',
        parameters: [
          'a',
          TsVector(lexemes: [
            Lexeme('abc', positions: [LexemePos(1)]),
            Lexeme('def'),
          ]),
        ],
      );
      final rs =
          await c.execute(r'SELECT * FROM t WHERE id = $1', parameters: ['a']);
      final row = rs.single;
      final tsv = row[1] as TsVector;
      expect(tsv.toString(), 'abc:1 def');
    });
  });
}
