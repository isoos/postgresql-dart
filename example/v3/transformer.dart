import 'dart:async';

import 'package:async/async.dart';
import 'package:postgres/messages.dart';
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:stream_channel/stream_channel.dart';

/// This example demonstrates how to ionstall a stream channel transformer
/// between this package and the posgres server that it is talking to.
///
/// This simple example uses the tranformer API to install a logger for each
/// logical message. By writing more complex transformers, you could also drop,
/// inject or alter messages in each direction.
/// For details, see the documentation of [StreamTransformer],
/// [StreamSinkTransformer] and [StreamChannelTransformer].
void main() async {
  final loggingTransformer = StreamChannelTransformer<BaseMessage, BaseMessage>(
    StreamTransformer.fromHandlers(
      handleData: (msg, sink) {
        print('[in] $msg');
        sink.add(msg);
      },
    ),
    StreamSinkTransformer.fromHandlers(handleData: (msg, sink) {
      print('[out] $msg');
      sink.add(msg);
    }),
  );

  final database = PgEndpoint(host: 'localhost', database: 'postgres');
  final connection = await PgConnection.open(database,
      sessionSettings: PgSessionSettings(transformer: loggingTransformer));

  await connection.execute(PgSql('SELECT 1;'));
  await connection.close();
}
