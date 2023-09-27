import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  usePostgresDocker();

  test('Reports stacktrace correctly', () async {
    final conn = PostgreSQLConnection('localhost', 5432, 'dart_test',
        username: 'dart', password: 'dart');
    await conn.open();
    addTearDown(() async => conn.close());

    // Root connection query
    try {
      await conn.query('SELECT hello');
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
      print(e);
      expect(e.toString(), contains('relation "hello" does not exist'));
      expect(
        st.toString(),
        contains('test/error_handling_test.dart'),
      );
    }

    // Inside transaction
    try {
      await conn.transaction((conn) async {
        await conn.query('SELECT hello');
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
}
