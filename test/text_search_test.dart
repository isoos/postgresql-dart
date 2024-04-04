import 'package:postgres/src/types/text_search.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('tsvector', (server) {
    test('decode output', () async {
      final c = await server.newConnection();
      final rs = await c.execute('SELECT \'x:11,12 yy:2A,4C\'::tsvector');
      final vector = rs.first.first as TsVector;
      expect(vector.words, hasLength(2));
      expect(vector.words.first.text, 'x');
      expect(vector.words.first.toString(), 'x:11,12');
      expect(vector.words.last.text, 'yy');
      expect(
        vector.words.last.positions?.map((e) => e.toString()).toList(),
        ['2A', '4C'],
      );
    });

    test('encode and decode', () async {
      final c = await server.newConnection();
      final rs = await c.execute(r'SELECT $1::tsvector', parameters: [
        TsVector(words: [
          TsWord('ab'),
          TsWord('cd', positions: [TsWordPos(4, weight: TsWeight.c)]),
        ])
      ]);
      final first = rs.first.first as TsVector;
      expect(first.words, hasLength(2));
      expect(first.words.first.text, 'ab');
      expect(first.words.first.positions, isNull);
      expect(first.words.last.text, 'cd');
      expect(first.words.last.positions?.single.toString(), '4C');
    });

    test('store and read', () async {
      final c = await server.newConnection();
      await c
          .execute('CREATE TABLE t (id TEXT, tsv TSVECTOR, PRIMARY KEY (id))');
      await c.execute(
        r'INSERT INTO t VALUES ($1, $2)',
        parameters: [
          'a',
          TsVector(words: [
            TsWord('abc', positions: [TsWordPos(1)]),
            TsWord('def'),
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

  withPostgresServer('tsquery', (server) {
    test('read and re-read queries', () async {
      final queries = <String, String?>{
        'x': "'x'",
        '!x': "!'x'",
        'x & y': "'x' & 'y'",
        'x | y': "'x' | 'y'",
        'x <-> y': "'x' <1> 'y'",
        'x <4> y': "'x' <4> 'y'",
        'x & !(y <2> z)': "'x' & !('y' <2> 'z')",
        'x & y & z & zz': "'x' & 'y' & 'z' & 'zz'",
        'x:A': "'x':A",
        'x:*': "'x':*",
        'x:A*B': "'x':*AB",
        'x:B & y:AC': "'x':B & 'y':AC",
      };
      final c = await server.newConnection();
      for (final e in queries.entries) {
        final rs = await c.execute("SELECT '${e.key}'::tsquery");
        final first = rs.first.first;
        final s1 = first.toString();
        expect(s1, e.value ?? e.key, reason: e.key);
        final rs2 = await c.execute(r'SELECT $1::tsquery', parameters: [first]);
        final s2 = rs2.first.first.toString();
        expect(s2, s1, reason: e.key);
      }
    });

    test('match queries to vectors', () async {
      final c = await server.newConnection();

      Future<void> expectMatch(
          TsVector vector, TsQuery query, bool expectedMatch) async {
        final rs = await c.execute(
          r'SELECT $1::tsvector @@ $2::tsquery',
          parameters: [vector, query],
        );
        expect(rs.first.first, expectedMatch);
      }

      final vector = TsVector(words: [
        TsWord('abc', positions: [TsWordPos(1)]),
        TsWord('cde', positions: [TsWordPos(2)]),
        TsWord('xyz', positions: [TsWordPos(3)]),
      ]);

      await expectMatch(
        vector,
        TsQuery.word('cd', prefix: true),
        true,
      );
      await expectMatch(
        vector,
        TsQuery.word('cde').followedBy(TsQuery.word('xyz')),
        true,
      );
      await expectMatch(
        vector,
        TsQuery.word('cde').followedBy(TsQuery.word('efg')),
        false,
      );
    });
  });
}
