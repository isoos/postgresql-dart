import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('not enough bytes to read', (server) {
    test('case #1', () async {
      final conn = await server.newConnection();
      await conn.execute(_testDdl, queryMode: QueryMode.simple);
      final rs1 = await conn.execute('SELECT l.id, bn.novel_id as novels '
          'FROM books l LEFT JOIN book_novel bn on l.id=bn.book_id;');
      expect(rs1.single, [359, null]);

      final rs2 =
          await conn.execute('SELECT l.id, ARRAY_AGG(bn.novel_id) as novels '
              'FROM books l LEFT JOIN book_novel bn on l.id=bn.book_id '
              'GROUP BY l.id;');
      expect(rs2.single, [
        359,
        [null]
      ]);
    });
  });
}

final _testDdl = '''
CREATE TABLE IF NOT EXISTS books (
    id        			INTEGER   NOT NULL PRIMARY KEY,
    title     			TEXT NOT NULL,
    first_publication 	INTEGER,
    notes      			TEXT,
    opinion_id 			INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS book_novel (
    book_id    INTEGER NOT NULL,
    novel_id INTEGER NOT NULL,
    PRIMARY KEY (book_id,novel_id)
);

INSERT INTO books (id,title,first_publication,notes,opinion_id) VALUES (359,'The legacy of heorot',1987,NULL,0);
INSERT INTO book_novel (book_id,novel_id) VALUES (1268,215);
''';
