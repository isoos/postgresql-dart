import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

import 'src/v3/connection.dart';
import 'src/v3/query_description.dart';
import 'src/v3/types.dart';

export 'src/types.dart';

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

class PgQueryDescription {
  factory PgQueryDescription.direct(String sql, {List<PgDataType>? types}) =
      InternalQueryDescription.direct;
  factory PgQueryDescription.map(String sql, {String substitution}) =
      InternalQueryDescription.map;
}

abstract class PgSession {
  // uses extended query protocol
  Future<PgStatement> prepare(
    Object /* String | InternalQueryDescription */ query, {
    Duration? timeout,
  });

  Future<PgResult> execute(
    Object /* String | InternalQueryDescription */ query, {
    Object? /* List<Object?|PgTypedParameter> | Map<String, Object?|PgTypedParameter> */ parameters,
    Duration? timeout,
  });

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
  }) {
    return PgConnectionImplementation.connect(endpoint,
        sessionSettings: sessionSettings);
  }

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

class PgResultSchema {
  final List<PgResultColumn> columns;

  PgResultSchema(this.columns);

  @override
  String toString() {
    return 'PgResultSchema(${columns.join(', ')})';
  }
}

class PgResultColumn {
  final PgDataType type;
  final String? tableName;
  final int? tableOid;
  final String? columnName;
  final int? columnOid;

  PgResultColumn({
    required this.type,
    this.tableName,
    this.tableOid,
    this.columnName,
    this.columnOid,
  });

  @override
  String toString() {
    final buffer = StringBuffer('${type.name} ');
    if (tableName != null && tableName != '') {
      buffer
        ..write(tableName)
        ..write('.');
    } else if (tableOid != null && tableOid != 0) {
      buffer
        ..write('@$tableOid')
        ..write('.');
    }

    if (columnName != null && columnName != '') {
      buffer.write(columnName);
    } else if (columnOid != null && columnOid != 0) {
      buffer.write('@$columnOid');
    }

    return buffer.toString();
  }
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

  Future<PgConnection> connect({PgSessionSettings? sessionSettings}) {
    return PgConnection.open(this, sessionSettings: sessionSettings);
  }
}

class PgSessionSettings {
  // Duration(seconds: 15)
  final Duration? connectTimeout;
  // Duration(minutes: 5)
  final Duration? queryTimeout;
  final String? timeZone;
  final Encoding? encoding;
  final bool Function(X509Certificate)? onBadSslCertificate;

  PgSessionSettings({
    this.connectTimeout,
    this.queryTimeout,
    this.timeZone,
    this.encoding,
    this.onBadSslCertificate,
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
