import 'dart:async';

import 'package:async/async.dart';
import 'package:postgres/messages.dart';
import 'package:postgres/postgres.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'docker.dart';

/// The server answers a failed statement with an ErrorResponse, then the
/// ReadyForQuery that ends it. Until the second arrives the statement is
/// still pending on the connection, and each session (the connection, a
/// `run` session, a transaction) has a lock of its own: a statement another
/// session starts in between is not held back by it.
///
/// So the error is reported once the ReadyForQuery has arrived. Reported at
/// the ErrorResponse, a caller could start that statement in the window,
/// which a busy machine opens by reading the two messages apart. Here the
/// ReadyForQuery is held back to open it every time.
void main() {
  withPostgresServer('a failed statement', (server) {
    late Connection connection;

    setUp(() async {
      connection = await Connection.open(
        await server.endpoint(),
        settings: ConnectionSettings(
          transformer: _holdReadyAfterError(const Duration(milliseconds: 300)),
        ),
      );
    });

    tearDown(() => connection.close());

    Future<Object?> two() async =>
        (await connection.run((s) => s.execute('SELECT 2'))).single.single;

    test('in a session ends before another session runs', () async {
      await expectLater(
        connection.run((s) => s.execute('SELECT 1/0')),
        throwsA(isA<ServerException>()),
      );
      expect(await two(), 2);
    });

    test('on the connection ends before a session runs', () async {
      await expectLater(
        connection.execute('SELECT 1/0'),
        throwsA(isA<ServerException>()),
      );
      expect(await two(), 2);
    });

    test('in the simple protocol ends before another session runs', () async {
      await expectLater(
        connection.run(
          (s) => s.execute('SELECT 1/0', queryMode: QueryMode.simple),
        ),
        throwsA(isA<ServerException>()),
      );
      expect(await two(), 2);
    });

    test(
      'cancelled for its timeout ends before another session runs',
      () async {
        await expectLater(
          connection.run(
            (s) => s.execute(
              'SELECT pg_sleep(5)',
              timeout: const Duration(milliseconds: 100),
            ),
          ),
          throwsA(isA<PgException>()),
        );
        expect(await two(), 2);
      },
    );
  });
}

/// Delivers a ReadyForQuery that follows an ErrorResponse [hold] late, and
/// everything after it with it.
StreamChannelTransformer<Message, Message> _holdReadyAfterError(Duration hold) {
  return StreamChannelTransformer<Message, Message>(
    StreamTransformer.fromBind((messages) {
      Message? last;
      return messages.asyncExpand((message) {
        final held =
            message is ReadyForQueryMessage && last is ErrorResponseMessage;
        last = message;
        return held
            ? Stream.fromFuture(Future.delayed(hold, () => message))
            : Stream.value(message);
      });
    }),
    StreamSinkTransformer.fromHandlers(),
  );
}
