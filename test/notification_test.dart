import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('Successful notifications', (server) {
    late Connection connection;
    setUp(() async {
      connection = await server.newConnection();
    });

    tearDown(() async {
      await connection.close();
    });

    test('Notification Response', () async {
      final channel = 'virtual';
      final payload = 'This is the payload';
      final futureMsg = connection.channels.all.first;
      await connection.execute(
        'LISTEN $channel;'
        "NOTIFY $channel, '$payload';",
        queryMode: QueryMode.simple,
      );

      final msg = await futureMsg.timeout(Duration(milliseconds: 200));
      expect(msg.channel, channel);
      expect(msg.payload, payload);
    });

    test('Notification Response empty payload', () async {
      final channel = 'virtual';
      final futureMsg = connection.channels.all.first;
      await connection.execute(
        'LISTEN $channel;'
        'NOTIFY $channel;',
        queryMode: QueryMode.simple,
      );

      final msg = await futureMsg.timeout(Duration(milliseconds: 200));
      expect(msg.channel, channel);
      expect(msg.payload, '');
    });

    test('Notification UNLISTEN', () async {
      final channel = 'virtual';
      final payload = 'This is the payload';
      var futureMsg = connection.channels.all.first;
      await connection.execute(
        'LISTEN $channel;'
        "NOTIFY $channel, '$payload';",
        queryMode: QueryMode.simple,
      );

      final msg = await futureMsg.timeout(Duration(milliseconds: 200));

      expect(msg.channel, channel);
      expect(msg.payload, payload);

      await connection.execute('UNLISTEN $channel;');

      futureMsg = connection.channels.all.first;

      try {
        await connection.execute(
          "NOTIFY $channel, '$payload';",
          queryMode: QueryMode.simple,
        );

        await futureMsg.timeout(Duration(milliseconds: 200));

        fail('There should be no notification');
      } on TimeoutException catch (_) {}
    });

    test('Notification many channel', () async {
      final countResponse = <String, int>{};
      var totalCountResponse = 0;
      final finishExecute = Completer();
      connection.channels.all.listen((msg) {
        final count = countResponse[msg.channel];
        countResponse[msg.channel] = (count ?? 0) + 1;
        totalCountResponse++;
        if (totalCountResponse == 20) finishExecute.complete();
      });

      final channel1 = 'virtual1';
      final channel2 = 'virtual2';

      Future<void> notifier() async {
        for (var i = 0; i < 5; i++) {
          await connection.execute(
            'NOTIFY $channel1;'
            'NOTIFY $channel2;',
            queryMode: QueryMode.simple,
          );
        }
      }

      await connection.execute('LISTEN $channel1;');
      await notifier();

      await connection.execute('LISTEN $channel2;');
      await notifier();

      await connection.execute('UNLISTEN $channel1;');
      await notifier();

      await connection.execute('UNLISTEN $channel2;');
      await notifier();

      await finishExecute.future.timeout(Duration(milliseconds: 200));

      expect(countResponse[channel1], 10);
      expect(countResponse[channel2], 10);
    }, timeout: Timeout(Duration(seconds: 5)));
  });
}
