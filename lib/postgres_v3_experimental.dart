import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';

abstract class PgPool implements PgSession, PgSessionExecutor {
  static Future<PgPool> open(
    List<PgEndpoint> endpoints, {
    PgSessionSettings? sessionSettings,
    PgPoolSettings? poolSettings,
  }) =>
      throw UnimplementedError();

  Future<R> withConnection<R>(
    Future<R> Function(PgConnection connection) fn, {
    PgSessionSettings? sessionSettings,
  });
}

abstract class PgSession {
  // uses extended query protocol
  Future<PgStatement> prepare(
    String sql, {
    Object? /* String */ substitution,
    Object? /* List<PgDataType> | Map<String, PgDataType> */ types,
    Duration? timeout,
  });

  Future<PgResult> execute(
    String sql, {
    Object? /* String */ substitution,
    Object? /* List<PgDataType> | Map<String, PgDataType> */ types,
    Object? /* List<Object?|PgTypedParameter> | Map<String, Object?|PgTypedParameter> */ parameters,
    Duration? timeout,
  }) async {
    if (substitution == null && types == null && parameters == null) {}
    final stmt = await prepare(
      sql,
      substitution: substitution,
      types: types,
      timeout: timeout,
    );
    try {
      return await stmt.run(parameters);
    } finally {
      await stmt.dispose();
    }
  }

  Future<void> close();
}

abstract class PgSessionExecutor {
  // TODO: also add retry options similarly to postgres_pool
  Future<R> run<R>(Future<R> Function(PgSession session) fn);
  Future<R> runTx<R>(Future<R> Function(PgSession session) fn);
}

abstract class PgConnection implements PgSession, PgSessionExecutor {
  static Future<PgConnection> open(
    PgEndpoint endpoint, {
    PgSessionSettings? sessionSettings,
  }) async =>
      throw UnimplementedError();

  PgChannels get channels;
  PgMessages get messages;
}

abstract class PgResultStream implements Stream<PgResultRow> {
  Future<int> get affectedRows;
  Future<PgResultSchema> get schema;
}

abstract class PgStatement {
  PgResultStream start(
    Object? /* List<Object?|PgTypedParameter> | Map<String, Object?|PgTypedParameter> */ parameters, {
    Duration? timeout,
  });

  Future<PgResult> run(
    Object? /* List<Object?|PgTypedParameter> | Map<String, Object?|PgTypedParameter> */ parameters, {
    Duration? timeout,
  }) async {
    final stream = start(parameters, timeout: timeout);
    final items = await stream.toList();
    return _PgResult(items, await stream.affectedRows, await stream.schema);
  }

  Future<void> dispose();
}

class PgTypedParameter {
  final PgDataType type;
  final Object? value;

  PgTypedParameter(this.type, this.value);
}

abstract class PgResult implements List<PgResultRow> {
  int get affectedRows;
  PgResultSchema get schema;
}

class _PgResult extends DelegatingList<PgResultRow> implements PgResult {
  @override
  final int affectedRows;

  @override
  final PgResultSchema schema;

  _PgResult(super.base, this.affectedRows, this.schema);
}

abstract class PgResultRow implements List<Object?> {
  PgResultSchema get schema;
}

abstract class PgResultSchema {
  List<PgResultColumn> get columns;
}

abstract class PgResultColumn {
  PgDataType get type;
  String? get tableName;
  int? get tableOid;
  String? get columnName;
  int? get columnOid;
}

enum PgDataType {
  text, // ... same as PostgresqlDataType?
}

abstract class PgChannels {
  Stream<String?> operator [](String channel);
  Future<void> notify(String channel, [String? payload]);
  Future<void> cancelAll();
}

abstract class PgMessages {
  Future<void> send(PgClientMessage message);
  Stream<PgServerMessage> get messages;
}

abstract class PgClientMessage {}

abstract class PgServerMessage {}

abstract class PgNotification {}

class PgEndpoint {
  final String host;
  final int port;
  final String database;
  final String? username;
  final String? password;
  final bool requireSsl;
  final bool isUnixSocket;

  PgEndpoint({
    required this.host,
    this.port = 5432,
    required this.database,
    this.username,
    this.password,
    this.requireSsl = false,
    this.isUnixSocket = false,
  });
}

class PgSessionSettings {
  // Duration(seconds: 15)
  final Duration? connectTimeout;
  // Duration(minutes: 5)
  final Duration? queryTimeout;
  final String? timeZone;
  final Encoding? encoding;

  PgSessionSettings({
    this.connectTimeout,
    this.queryTimeout,
    this.timeZone,
    this.encoding,
  });
}

class PgPoolSettings {
  final int? maxConnectionCount;
  final Duration? idleTestThreshold;
  final Duration? maxConnectionAge;
  final Duration? maxSessionUse;
  final int? maxErrorCount;
  final int? maxQueryCount;

  PgPoolSettings({
    this.maxConnectionCount,
    this.idleTestThreshold,
    this.maxConnectionAge,
    this.maxSessionUse,
    this.maxErrorCount,
    this.maxQueryCount,
  });
}
