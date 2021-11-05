import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  usePostgresDocker();

  test('Reports stacktrace correctly', () async {
    final conn = PostgreSQLConnection('localhost', 5432, 'dart_test', username: 'dart', password: 'dart');
    await conn.open();
    addTearDown(() async => conn.close());

    try {
      await conn.query('SELECT hello');
      fail('Should not reach');
    } catch (e, st) {
      expect(st.toString(), isNotEmpty);
      expect(st.toString(), contains('postgresql-dart/test/error_handling_test.dart'));
    }
  });
}
