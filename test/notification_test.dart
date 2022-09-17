import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {

  usePostgresDocker();

  group('Successful notifications', () {
    late PostgreSQLConnection connection;
    setUp(() async {
      connection = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');
      await connection.open();
    });

    tearDown(() async {
      await connection.close();
    });

    test('Notification Response', () async {
      final channel = 'virtual';
      final payload = 'This is the payload';
      final futureMsg = connection.notifications.first;
      await connection.execute('LISTEN $channel;'
          "NOTIFY $channel, '$payload';");

      final msg = await futureMsg.timeout(Duration(milliseconds: 200));
      expect(msg.channel, channel);
      expect(msg.payload, payload);
    });

    test('Notification Response empty payload', () async {
      final channel = 'virtual';
      final futureMsg = connection.notifications.first;
      await connection.execute('LISTEN $channel;'
          'NOTIFY $channel;');

      final msg = await futureMsg.timeout(Duration(milliseconds: 200));
      expect(msg.channel, channel);
      expect(msg.payload, '');
    });

    test('Notification UNLISTEN', () async {
      final channel = 'virtual';
      final payload = 'This is the payload';
      var futureMsg = connection.notifications.first;
      await connection.execute('LISTEN $channel;'
          "NOTIFY $channel, '$payload';");

      final msg = await futureMsg.timeout(Duration(milliseconds: 200));

      expect(msg.channel, channel);
      expect(msg.payload, payload);

      await connection.execute('UNLISTEN $channel;');

      futureMsg = connection.notifications.first;

      try {
        await connection.execute("NOTIFY $channel, '$payload';");

        await futureMsg.timeout(Duration(milliseconds: 200));

        fail('There should be no notification');
      } on TimeoutException catch (_) {}
    });

    test('Notification many channel', () async {
      final countResponse = <String, int>{};
      var totalCountResponse = 0;
      final finishExecute = Completer();
      connection.notifications.listen((msg) {
        final count = countResponse[msg.channel];
        countResponse[msg.channel] = (count ?? 0) + 1;
        totalCountResponse++;
        if (totalCountResponse == 20) finishExecute.complete();
      });

      final channel1 = 'virtual1';
      final channel2 = 'virtual2';

      final notifier = () async {
        for (var i = 0; i < 5; i++) {
          await connection.execute('NOTIFY $channel1;'
              'NOTIFY $channel2;');
        }
      };

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
