import 'dart:io';

import 'package:postgres/postgres_v3_experimental.dart';

const channel = 'my_channel';

/// Demonstrates how to use the `NOTIFY` mechanism in postgres in the v3 version
/// of the postgres Dart package.
///
/// For details, see https://www.postgresql.org/docs/current/sql-notify.html
void main(List<String> args) async {
  final command = args.isEmpty ? null : args.first;

  if (command == 'listen') {
    final database = PgEndpoint(host: 'localhost', database: 'postgres');
    final connection = await database.connect();

    // Notifications are exposed as streams, the postgres package will
    // automatically issue the `LISTEN` AND `UNLISTEN` commands as the stream
    // subscription is created or cancelled.
    final stream = connection.channels[channel];
    stream.listen((event) {
      print('Received asynchronous notification: "$event"');
    });

    print('Listening on channel "$channel". To send a notification, use ');
    print(' - dart run example/v3/notify.dart notify [payload]');
    print(" - `NOTIFY $channel, 'payload'` in `psql`");
  } else if (command == 'notify') {
    final payload = args.length > 1 ? args[1] : null;

    final database = PgEndpoint(host: 'localhost', database: 'postgres');
    final connection = await database.connect();

    await connection.channels.notify(channel, payload);
    await connection.close();
  } else {
    stderr.writeln('Usage: dart run example/v3/notify.dart <listen|notify>');
    await stderr.flush();
    exit(1);
  }
}
