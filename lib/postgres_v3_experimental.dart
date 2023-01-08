import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:stream_channel/stream_channel.dart';

import 'src/v3/connection.dart';
import 'src/v3/protocol.dart';
import 'src/v3/query_description.dart';
import 'src/v3/types.dart';

export 'src/v3/types.dart';

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

class PgSql {
  factory PgSql(String sql, {List<PgDataType>? types}) =
      InternalQueryDescription.direct;
  factory PgSql.map(String sql, {String substitution}) =
      InternalQueryDescription.map;
}

abstract class PgSession {
  // uses extended query protocol
  Future<PgStatement> prepare(
    Object /* String | PgSql */ query, {
    Duration? timeout,
  });

  Future<PgResult> execute(
    Object /* String | PgSql */ query, {
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
}

abstract class PgResultStream implements Stream<PgResultRow> {
  @override
  PgResultStreamSubscription listen(void Function(PgResultRow event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError});
}

abstract class PgResultStreamSubscription
    implements StreamSubscription<PgResultRow> {
  Future<int> get affectedRows;
  Future<PgResultSchema> get schema;
}

abstract class PgStatement {
  PgResultStream bind(
      Object? /* List<Object?|PgTypedParameter> | Map<String, Object?|PgTypedParameter> */ parameters);

  Future<PgResult> run(
    Object? /* List<Object?|PgTypedParameter> | Map<String, Object?|PgTypedParameter> */ parameters, {
    Duration? timeout,
  }) async {
    final items = <PgResultRow>[];
    final subscription = bind(parameters).listen(items.add);
    await subscription.asFuture();
    await subscription.cancel();

    return PgResult(
        items, await subscription.affectedRows, await subscription.schema);
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

  factory PgResult(
          List<PgResultRow> rows, int affectedRows, PgResultSchema schema) =
      _PgResult;
}

class _PgResult extends DelegatingList<PgResultRow> implements PgResult {
  @override
  final int affectedRows;

  @override
  final PgResultSchema schema;

  final List<PgResultRow> rows;

  _PgResult(this.rows, this.affectedRows, this.schema) : super(rows);

  @override
  String toString() {
    return 'PgResult(schema = $schema, affectedRows = $affectedRows, rows = $rows)';
  }
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
  Stream<String> operator [](String channel);
  Future<void> notify(String channel, [String? payload]);
  Future<void> cancelAll();
}

abstract class PgNotification {}

class PgEndpoint {
  final String host;
  final int port;
  final String database;
  final String? username;
  final String? password;
  final bool requireSsl;
  final bool isUnixSocket;

  /// An optional [StreamChannelTransformer] sitting behind the postgres client
  /// as implemented in the `posgres` package and the database server.
  ///
  /// The stream channel transformer is able to view, alter, drop, or inject
  /// messages in either direction. This powerful tool can be used to implement
  /// additional or custom functionality, but should also be used with caution
  /// as altering the message flow might break internal invariants of this
  /// package.
  ///
  /// For an example, see `example/v3/transformer.dart`.
  final StreamChannelTransformer<BaseMessage, BaseMessage>? transformer;

  PgEndpoint({
    required this.host,
    this.port = 5432,
    required this.database,
    this.username,
    this.password,
    this.requireSsl = false,
    this.isUnixSocket = false,
    this.transformer,
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
