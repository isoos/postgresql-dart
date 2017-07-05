import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  group("Successful notifications", () {
    var connection = new PostgreSQLConnection("localhost", 5432, "dart_test",
        username: "dart", password: "dart");

    setUp(() async {
      connection = new PostgreSQLConnection("localhost", 5432, "dart_test",
          username: "dart", password: "dart");
      await connection.open();
    });

    tearDown(() async {
      await connection.close();
    });

    test("Notification Response", () async {
      var channel = 'virtual';
      var payload = 'This is the payload';
      var futureMsg = connection.notifications.first;
      await connection
          .execute("LISTEN $channel;"
                   "NOTIFY $channel, '$payload';");

      var msg = await futureMsg
          .timeout(new Duration(milliseconds: 200));
      expect(msg.channel, channel);
      expect(msg.payload, payload);
    });

    test("Notification Response empty payload", () async {
      var channel = 'virtual';
      var futureMsg = connection.notifications.first;
      await connection
          .execute("LISTEN $channel;"
                   "NOTIFY $channel;");

      var msg = await futureMsg
          .timeout(new Duration(milliseconds: 200));
      expect(msg.channel, channel);
      expect(msg.payload, '');
    });

    test("Notification UNLISTEN", () async {
      var channel = 'virtual';
      var payload = 'This is the payload';
      var futureMsg = connection.notifications.first;
      await connection
          .execute("LISTEN $channel;"
          "NOTIFY $channel, '$payload';");

      var msg = await futureMsg
          .timeout(new Duration(milliseconds: 200));

      expect(msg.channel, channel);
      expect(msg.payload, payload);

      await connection
          .execute("UNLISTEN $channel;");

      futureMsg = connection.notifications.first;

      try {
        await connection
            .execute("NOTIFY $channel, '$payload';");

        await futureMsg
            .timeout(new Duration(milliseconds: 200));

        fail('There should be no notification');
      } on TimeoutException catch (_) {}
    });

    test("Notification many channel", () async {
      Map<String, int> countResponse = new Map<String, int>();
      int totalCountResponse = 0;
      Completer finishExecute = new Completer();
      connection.notifications.listen((msg){
        int count = countResponse[msg.channel];
        countResponse[msg.channel] = (count ?? 0) + 1;
        totalCountResponse++;
        if(totalCountResponse == 20)
          finishExecute.complete();
      });

      var channel1 = 'virtual1';
      var channel2 = 'virtual2';

      var notifier = () async {
        for (int i = 0; i < 5; i++) {
          await connection
              .execute("NOTIFY $channel1;"
              "NOTIFY $channel2;");
        }
      };

      await connection
          .execute("LISTEN $channel1;");
      await notifier();

      await connection
          .execute("LISTEN $channel2;");
      await notifier();

      await connection
          .execute("UNLISTEN $channel1;");
      await notifier();

      await connection
          .execute("UNLISTEN $channel2;");
      await notifier();

      await finishExecute.future
          .timeout(new Duration(milliseconds: 200));

      expect(countResponse[channel1], 10);
      expect(countResponse[channel2], 10);
    }, timeout: new Timeout(new Duration(seconds: 5)));
  });
}
