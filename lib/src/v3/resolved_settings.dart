import 'dart:convert';
import 'dart:io';

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
  final bool ignoreSuperfluousParameters;

  ResolvedSessionSettings(SessionSettings? settings, SessionSettings? fallback)
      : connectTimeout = settings?.connectTimeout ??
            fallback?.connectTimeout ??
            Duration(seconds: 15),
        queryTimeout = settings?.queryTimeout ??
            fallback?.queryTimeout ??
            Duration(minutes: 5),
        queryMode =
            settings?.queryMode ?? fallback?.queryMode ?? QueryMode.extended,
        ignoreSuperfluousParameters = settings?.ignoreSuperfluousParameters ??
            fallback?.ignoreSuperfluousParameters ??
            false;

  bool isMatchingSession(ResolvedSessionSettings other) {
    return connectTimeout == other.connectTimeout &&
        queryTimeout == other.queryTimeout &&
        queryMode == other.queryMode &&
        ignoreSuperfluousParameters == other.ignoreSuperfluousParameters;
  }
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
  final SecurityContext? securityContext;
  @override
  final StreamChannelTransformer<Message, Message>? transformer;
  @override
  final ReplicationMode replicationMode;
  @override
  final TypeRegistry typeRegistry;
  @override
  final Future<void> Function(Connection connection)? onOpen;

  ResolvedConnectionSettings(
      ConnectionSettings? super.settings, ConnectionSettings? super.fallback)
      : applicationName =
            settings?.applicationName ?? fallback?.applicationName,
        timeZone = settings?.timeZone ?? fallback?.timeZone ?? 'UTC',
        encoding = settings?.encoding ?? fallback?.encoding ?? utf8,
        sslMode = settings?.sslMode ?? fallback?.sslMode ?? SslMode.require,
        securityContext = settings?.securityContext,
        // TODO: consider merging the transformers
        transformer = settings?.transformer ?? fallback?.transformer,
        replicationMode = settings?.replicationMode ??
            fallback?.replicationMode ??
            ReplicationMode.none,
        // TODO: consider merging the type registries
        typeRegistry =
            settings?.typeRegistry ?? fallback?.typeRegistry ?? TypeRegistry(),
        onOpen = settings?.onOpen ?? fallback?.onOpen;

  bool isMatchingConnection(ResolvedConnectionSettings other) {
    return isMatchingSession(other) &&
        applicationName == other.applicationName &&
        timeZone == other.timeZone &&
        encoding == other.encoding &&
        sslMode == other.sslMode &&
        transformer == other.transformer &&
        replicationMode == other.replicationMode &&
        onOpen == other.onOpen;
  }
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

  ResolvedPoolSettings(PoolSettings? settings)
      : maxConnectionCount = settings?.maxConnectionCount ?? 1,
        maxConnectionAge = settings?.maxConnectionAge ?? Duration(hours: 12),
        maxSessionUse = settings?.maxSessionUse ?? Duration(hours: 4),
        maxQueryCount = settings?.maxQueryCount ?? 100000,
        super(settings, null);
}

class ResolvedTransactionSettings extends ResolvedSessionSettings
    implements TransactionSettings {
  @override
  final IsolationLevel? isolationLevel;
  @override
  final AccessMode? accessMode;
  @override
  final DeferrableMode? deferrable;

  ResolvedTransactionSettings(
      TransactionSettings? super.settings, super.fallback)
      : isolationLevel = settings?.isolationLevel,
        accessMode = settings?.accessMode,
        deferrable = settings?.deferrable;
}
