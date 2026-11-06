import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../support/docker.dart';

void main() {
  withPostgresServer('transaction status', (server) {
    test('tracks BEGIN, failure, COMMIT and ROLLBACK', () async {
      final c = await Connection.open(await server.endpoint());
      addTearDown(c.close);

      expect(c.transactionStatus, TransactionStatus.idle);
      await c.execute('BEGIN');
      expect(c.transactionStatus, TransactionStatus.transaction);
      await c.execute('SELECT 1');
      expect(c.transactionStatus, TransactionStatus.transaction);

      await expectLater(
        c.execute('SELECT * FROM no_such_table'),
        throwsA(isA<PgException>()),
      );
      expect(c.transactionStatus, TransactionStatus.error);

      // COMMIT on a failed transaction silently rolls back.
      await c.execute('COMMIT');
      expect(c.transactionStatus, TransactionStatus.idle);

      await c.execute('BEGIN');
      await c.execute('ROLLBACK');
      expect(c.transactionStatus, TransactionStatus.idle);
    });
  });
}
