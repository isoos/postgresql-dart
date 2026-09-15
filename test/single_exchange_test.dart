import 'dart:async';

import 'package:async/async.dart';
import 'package:postgres/messages.dart';
import 'package:postgres/postgres.dart';
import 'package:postgres/src/v3/protocol.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'docker.dart';

/// Everything between two Sync messages is one transaction, so a query that
/// sends a Sync between parsing and binding is two of them. A pooler in
/// transaction mode hands the server connection to another client at the
/// ReadyForQuery a Sync produces, and the bind then arrives somewhere that
/// never saw the parse -- or worse, somewhere still holding another client's
/// statement of the same generated name.
///
/// So parse, bind and execute travel together.
void main() {
  withPostgresServer('single exchange', (server) {
    late List<ClientMessage> sent;
    late Connection connection;

    setUp(() async {
      sent = [];
      connection = await Connection.open(
        await server.endpoint(),
        settings: ConnectionSettings(
          transformer: StreamChannelTransformer<Message, Message>(
            StreamTransformer.fromHandlers(),
            StreamSinkTransformer.fromHandlers(
              handleData: (message, sink) {
                // Messages travel batched, so what was sent is what the
                // batches hold.
                if (message is AggregatedClientMessage) {
                  sent.addAll(message.messages);
                } else if (message is ClientMessage) {
                  sent.add(message);
                }
                sink.add(message);
              },
            ),
          ),
        ),
      );
      // Connecting is not what is under test.
      sent.clear();
    });

    tearDown(() => connection.close());

    /// What was sent, up to and including the execute.
    Iterable<ClientMessage> throughExecute() =>
        sent.takeWhile((message) => message is! ExecuteMessage).followedBy([
          sent.whereType<ExecuteMessage>().first,
        ]);

    test('a parameterised query parses and binds without a sync between', () async {
      await connection.execute(r'SELECT $1::int AS value', parameters: [1]);

      expect(
        throughExecute().map((message) => message.runtimeType).toList(),
        [ParseMessage, BindMessage, DescribeMessage, ExecuteMessage],
      );
    });

    test('a query without parameters is one exchange too', () async {
      await connection.execute('SELECT 1 AS value');

      expect(
        throughExecute().whereType<SyncMessage>(),
        isEmpty,
        reason: 'a sync before the execute would end the transaction that parsed',
      );
    });

    test('the statement it parses is the unnamed one, which cannot collide', () async {
      await connection.execute(r'SELECT $1::int AS value', parameters: [1]);

      expect(sent.whereType<ParseMessage>().single.statementName, isEmpty);
    });

    test('a one-shot query does not close the statement it never named', () async {
      await connection.execute(r'SELECT $1::int AS value', parameters: [1]);

      expect(
        sent.whereType<CloseMessage>(),
        isEmpty,
        reason: 'the next parse replaces the unnamed statement, so closing it is an exchange that changes nothing',
      );
    });

    test('a named statement is still closed, because its name has to become free again', () async {
      final statement = await connection.prepare(r'SELECT $1::int AS value');
      await statement.dispose();

      expect(sent.whereType<CloseMessage>(), isNotEmpty);
    });

    test('a statement kept for reuse is still named and still parsed on its own', () async {
      final statement = await connection.prepare(r'SELECT $1::int AS value');
      addTearDown(statement.dispose);

      final parse = sent.whereType<ParseMessage>().single;
      expect(parse.statementName, isNotEmpty);
      // Nothing binds it yet, so its exchange ends where it was sent.
      expect(sent.whereType<BindMessage>(), isEmpty);
    });

    test('the results are what was asked for', () async {
      final result = await connection.execute(
        r'SELECT $1::text AS value, $2::int AS count',
        parameters: ['hello', 3],
      );

      expect(result.first.toColumnMap(), {'value': 'hello', 'count': 3});
    });
  });
}
