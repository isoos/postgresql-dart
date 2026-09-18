import 'dart:async';
import 'dart:typed_data';

import 'package:postgres/postgres.dart';
import 'package:postgres/src/v3/connection.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('timeout', (server) {
    late Connection conn;

    setUp(() async {
      conn = await server.newConnection();
      await conn.execute('CREATE TEMPORARY TABLE t (id INT UNIQUE)');
    });

    tearDown(() async {
      await conn.close();
    });

    test('Cancel current statement through a new connection', () async {
      // Not awaited until after the cancel request below, which does real
      // network I/O - ignore it in the meantime so a rejection arriving
      // during that gap isn't flagged as an unhandled error by the zone.
      final f = conn.execute('SELECT pg_sleep(2);')..ignore();
      await (conn as PgConnectionImplementation).cancelPendingStatement();
      await expectLater(
        f,
        throwsA(allOf(isA<PgException>(), isA<TimeoutException>())),
      );
      // connection is still usable
      final rs = await conn.execute('SELECT 1;');
      expect(rs[0][0], 1);
    });

    test('Timeout fires during transaction rolls ack transaction', () async {
      try {
        await conn.runTx((ctx) async {
          await ctx.execute('INSERT INTO t (id) VALUES (1)');
          await ctx.execute(
            'SELECT pg_sleep(2)',
            timeout: Duration(seconds: 1),
          );
        });
        fail('unreachable');
      } on TimeoutException {
        // ignore
      }

      expect(await conn.execute('SELECT * from t'), hasLength(0));
    });

    test(
      'Timeout is ignored when new statement is run on parent context',
      () async {
        try {
          await conn.runTx((ctx) async {
            await conn.execute('SELECT 1', timeout: Duration(seconds: 1));
            await ctx.execute('INSERT INTO t (id) VALUES (1)');
          });
          fail('unreachable');
        } on PgException catch (e) {
          expect(e.message, contains('runTx'));
          // ignore
        }

        expect(await conn.execute('SELECT * from t'), hasLength(0));
      },
    );

    test(
      'If query is already on the wire and times out, safely throws timeoutexception and nothing else',
      () async {
        try {
          await conn.execute(
            'SELECT pg_sleep(2)',
            timeout: Duration(seconds: 1),
          );
          fail('unreachable');
        } on TimeoutException {
          // ignore
        }
      },
    );

    test('Query times out, next query in the queue runs', () async {
      final rs = await conn.execute('SELECT 1');
      unawaited(
        conn
            .execute('SELECT pg_sleep(2)', timeout: Duration(seconds: 1))
            .catchError((_) => rs),
      );

      expect(await conn.execute('SELECT 1'), [
        [1],
      ]);
    });

    test('Query that succeeds does not timeout', () async {
      await conn.execute('SELECT 1', timeout: Duration(seconds: 1));
    });

    test('Hard timeout releases the operation lock even if the server never '
        'confirms the cancel', () async {
      var dropIncoming = false;
      final faultyConn = await PgConnectionImplementation.connect(
        await server.endpoint(),
        connectionSettings: ConnectionSettings(
          connectTimeout: Duration(seconds: 2),
        ),
        incomingBytesTransformer: StreamTransformer.fromHandlers(
          handleData: (Uint8List data, EventSink<Uint8List> sink) {
            if (!dropIncoming) sink.add(data);
          },
        ),
      );
      addTearDown(() => faultyConn.close(force: true));

      final f = faultyConn.execute(
        'SELECT pg_sleep(5)',
        timeout: Duration(milliseconds: 300),
      )..ignore();
      // Let the query reach the server before dropping further bytes, so
      // the eventual cancel request never gets a visible response (no
      // error message, no ReadyForQueryMessage) - forcing the hard-timeout
      // fallback in `_waitForResult` to fire instead of the graceful
      // cancel path.
      await Future<void>.delayed(Duration(milliseconds: 50));
      dropIncoming = true;

      await expectLater(f, throwsA(isA<TimeoutException>()));

      // Without the fix, the connection's operation lock stays stuck
      // forever and this call hangs; with the fix, the connection is
      // force-closed and this fails fast instead.
      await expectLater(
        faultyConn.execute('SELECT 1'),
        throwsA(isA<PgException>()),
      );
    });

    test('runTx preserves the original exception when the rollback also times '
        'out', () async {
      var dropIncoming = false;
      final faultyConn = await PgConnectionImplementation.connect(
        await server.endpoint(),
        connectionSettings: ConnectionSettings(
          connectTimeout: Duration(seconds: 2),
          queryTimeout: Duration(milliseconds: 300),
        ),
        incomingBytesTransformer: StreamTransformer.fromHandlers(
          handleData: (Uint8List data, EventSink<Uint8List> sink) {
            if (!dropIncoming) sink.add(data);
          },
        ),
      );
      addTearDown(() => faultyConn.close(force: true));

      final f = faultyConn.runTx((ctx) async {
        // BEGIN's response has already arrived by now - drop everything
        // from here on, so the ROLLBACK this throw triggers never gets a
        // response and times out internally too.
        dropIncoming = true;
        throw StateError('boom');
      });

      // The original StateError must win, not the internal ROLLBACK's
      // TimeoutException - and this must not hang forever either.
      await expectLater(f, throwsA(isA<StateError>()));
    });

    test('Query that fails does not timeout', () async {
      final rs = await conn.execute('SELECT 1');
      Exception? caught;
      await conn
          .execute(
            "INSERT INTO t (id) VALUES ('foo')",
            timeout: Duration(seconds: 1),
          )
          .catchError((e) {
            caught = e;
            // needs this to match return type
            return rs;
          });
      expect(caught, isA<ServerException>());
    });
  });

  // Note: to fix this, we may consider cancelling the currently running statements:
  //       https://www.postgresql.org/docs/current/protocol-flow.html#PROTOCOL-FLOW-CANCELING-REQUESTS
  withPostgresServer('timeout race conditions', (server) {
    setUp(() async {
      final c1 = await server.newConnection();
      await c1.execute('CREATE TABLE t (id INT PRIMARY KEY);');
      await c1.execute('INSERT INTO t (id) values (1);');
    });

    test('two transactions for update', () async {
      for (final qm in QueryMode.values) {
        final c1 = await server.newConnection();
        final c2 = await server.newConnection(queryMode: qm);
        await c1.execute('BEGIN');
        await c1.execute('SELECT * FROM t WHERE id=1 FOR UPDATE');
        await c2.execute('BEGIN');
        try {
          await c2.execute(
            'SELECT * FROM t WHERE id=1 FOR UPDATE',
            timeout: Duration(seconds: 1),
          );
          fail('unreachable');
        } on TimeoutException catch (_) {
          // ignore
        }
        await c1.execute('ROLLBACK');
        await c2.execute('ROLLBACK');

        await c1.execute('SELECT 1');
        await c2.execute('SELECT 1');
      }
    });
  });
}
