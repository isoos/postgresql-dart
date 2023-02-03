import 'dart:async';

import 'package:async/async.dart';
import 'package:postgres/messages.dart';
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'docker.dart';

final _endpoint = PgEndpoint(
  host: 'localhost',
  database: 'dart_test',
  username: 'dart',
  password: 'dart',
);

final _sessionSettings = PgSessionSettings(
  // To test SSL, we're running postgres with a self-signed certificate.
  onBadSslCertificate: (cert) => true,
);

void main() {
  usePostgresDocker();

  group('PgConnection', () {
    late PgConnection connection;

    setUp(() async {
      connection =
          await PgConnection.open(_endpoint, sessionSettings: _sessionSettings);
    });

    tearDown(() => connection.close());

    test('simple queries', () async {
      expect(await connection.execute("SELECT 'dart', 42, NULL"), [
        ['dart', 42, null]
      ]);
    });

    test('queries without a schema message', () async {
      final response =
          await connection.execute('CREATE TEMPORARY TABLE foo (bar INTEGER);');
      expect(response.affectedRows, isZero);
      expect(response.schema.columns, isEmpty);
    });

    group('binary encoding and decoding', () {
      Future<void> shouldPassthrough<T extends Object>(
          PgDataType<T> type, T? value) async {
        final stmt =
            await connection.prepare(PgSql(r'SELECT $1', types: [type]));
        final result = await stmt.run([value]);
        await stmt.dispose();

        expect(result, [
          [value]
        ]);
      }

      test('string', () async {
        await shouldPassthrough<String>(PgDataType.text, null);
        await shouldPassthrough<String>(PgDataType.text, 'hello world');
      });

      test('int', () async {
        await shouldPassthrough<int>(PgDataType.smallInteger, null);
        await shouldPassthrough<int>(PgDataType.smallInteger, 42);
        await shouldPassthrough<int>(PgDataType.integer, 1024);
        await shouldPassthrough<int>(PgDataType.bigInteger, 999999999999);
      });
    });

    test('listen and notify', () async {
      const channel = 'test_channel';

      expect(connection.channels[channel],
          emitsInOrder(['my notification', isEmpty]));

      await connection.channels.notify(channel, 'my notification');
      await connection.channels.notify(channel);
    });
  });

  test('can inject transformer into connection', () async {
    final incoming = <ServerMessage>[];
    final outgoing = <ClientMessage>[];

    final transformer = StreamChannelTransformer<BaseMessage, BaseMessage>(
      StreamTransformer.fromHandlers(
        handleData: (msg, sink) {
          incoming.add(msg as ServerMessage);
          sink.add(msg);
        },
      ),
      StreamSinkTransformer.fromHandlers(handleData: (msg, sink) {
        outgoing.add(msg as ClientMessage);
        sink.add(msg);
      }),
    );

    final connection = await PgConnection.open(
      _endpoint,
      sessionSettings: PgSessionSettings(
        transformer: transformer,
        onBadSslCertificate: (_) => true,
      ),
    );
    addTearDown(connection.close);

    await connection.execute("SELECT 'foo'");
    expect(incoming, contains(isA<DataRowMessage>()));
    expect(outgoing, contains(isA<QueryMessage>()));
  });
}
