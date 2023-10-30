import 'dart:convert';

import 'package:postgres/messages.dart';
import 'package:stream_channel/stream_channel.dart';

import '../../postgres.dart';

class ResolvedSessionSettings implements SessionSettings {
  @override
  final Duration connectTimeout;
  @override
  final Duration queryTimeout;
  @override
  final QueryMode queryMode;
  @override
  final bool allowSuperfluousParameters;

  ResolvedSessionSettings(SessionSettings? settings)
      : connectTimeout = settings?.connectTimeout ?? Duration(seconds: 15),
        queryTimeout = settings?.queryTimeout ?? Duration(minutes: 5),
        queryMode = settings?.queryMode ?? QueryMode.extended,
        allowSuperfluousParameters =
            settings?.allowSuperfluousParameters ?? false;
}

class ResolvedConnectionSettings extends ResolvedSessionSettings
    implements ConnectionSettings {
  @override
  final String? applicationName;
  @override
  final String timeZone;
  @override
  final Encoding encoding;
  @override
  final SslMode sslMode;
  @override
  final StreamChannelTransformer<Message, Message>? transformer;
  @override
  final ReplicationMode replicationMode;

  ResolvedConnectionSettings(ConnectionSettings? super.settings)
      : applicationName = settings?.applicationName,
        timeZone = settings?.timeZone ?? 'UTC',
        encoding = settings?.encoding ?? utf8,
        sslMode = settings?.sslMode ?? SslMode.require,
        transformer = settings?.transformer,
        replicationMode = settings?.replicationMode ?? ReplicationMode.none;
}

class ResolvedPoolSettings extends ResolvedConnectionSettings
    implements PoolSettings {
  @override
  final int maxConnectionCount;
  @override
  final Duration maxConnectionAge;
  @override
  final Duration maxSessionUse;
  @override
  final int maxQueryCount;

  ResolvedPoolSettings(PoolSettings? super.settings)
      : maxConnectionCount = settings?.maxConnectionCount ?? 1,
        maxConnectionAge = settings?.maxConnectionAge ?? Duration(hours: 12),
        maxSessionUse = settings?.maxSessionUse ?? Duration(hours: 4),
        maxQueryCount = settings?.maxQueryCount ?? 100000;
}

class ResolvedTransactionSettings extends ResolvedSessionSettings
    implements TransactionSettings {
  @override
  final IsolationLevel? isolationLevel;
  @override
  final AccessMode? accessMode;
  @override
  final DeferrableMode? deferrable;

  ResolvedTransactionSettings(TransactionSettings? super.settings)
      : isolationLevel = settings?.isolationLevel,
        accessMode = settings?.accessMode,
        deferrable = settings?.deferrable;
}
