import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('error handling', (server) {
    test('Reports stacktrace correctly', () async {
      final conn = await server.newConnection();
      addTearDown(() async => conn.close());

      // Root connection query
      try {
        await conn.execute('SELECT hello');
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
        expect(e.toString(), contains('relation "hello" does not exist'));
        expect(
          st.toString(),
          contains('test/error_handling_test.dart'),
        );
      }

      // Inside transaction
      try {
        await conn.runTx((s) async {
          await s.execute('SELECT hello');
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
  });
}
