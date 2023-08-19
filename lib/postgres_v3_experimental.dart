import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:postgres/src/replication.dart';
import 'package:stream_channel/stream_channel.dart';

import 'src/v3/connection.dart';
import 'src/v3/pool.dart';
import 'src/v3/protocol.dart';
import 'src/v3/query_description.dart';
import 'src/v3/types.dart';

export 'src/v3/types.dart';

abstract class PgPool implements PgSession, PgSessionExecutor {
  factory PgPool(
    List<PgEndpoint> endpoints, {
    PgSessionSettings? sessionSettings,
    PgPoolSettings? poolSettings,
  }) =>
      PoolImplementation(endpoints, sessionSettings, poolSettings);

  /// Acquires a connection from this pool, opening a new one if necessary, and
  /// calls [fn] with it.
  ///
  /// The connection must not be used after [fn] returns as it could be used by
  /// another [withConnection] call later.
  Future<R> withConnection<R>(
    Future<R> Function(PgConnection connection) fn, {
    PgSessionSettings? sessionSettings,
  });
}

/// A description of a SQL query as interpreted by this package.
///
/// This includes the SQL string to send to the database and known data types
/// for parameters, if any.
///
/// Queries can be sent to postgres as-is. To do that, pass a string to
/// [PgSession.prepare] or [PgSession.execute] or use the default [PgSql]
/// constructor. These queries are not intepreted or altered by this package in
/// any way. If you're using parameter in those queries, you either have to
/// specify their types in the [PgSql] constructor, or exclusively use
/// [PgTypedParameter] instances in [PgSession.execute], [PgStatement.bind] and
/// [PgStatement.run].
///
/// Alternatively, you can use named variables that will be desugared by this
/// package with the [PgSql.map] factory.
class PgSql {
  /// The default constructor, sending [sql] to the Postgres database without
  /// any modification.
  ///
  /// The [types] parameter can optionally be used to pass the types of
  /// parameters in the query. If they're not set, only [PgTypedParameter]
  /// instances can be used when binding values later.
  factory PgSql(String sql, {List<PgDataType>? types}) =
      InternalQueryDescription.direct;

  /// Looks for named parameters in [sql] and desugars them.
  ///
  /// You can specify a character that starts parameters (by default, `@` is
  /// used).
  /// In those queries, `@variableName` can be used to declare a variable.
  ///
  /// ```dart
  /// final sql = PgSql.map('SELECT * FROM users WHERE id = @id');
  /// final stmt = await connection.prepare(sql);
  /// final vars = {'id': PgTypedParameter(PgDataType.integer, 3)};
  /// await for (final row in stmt.bind(vars)) {
  ///   // Got user with id 3
  /// }
  /// ```
  ///
  /// To make this more consise, you can also supply the type of the variable
  /// in the query:
  ///
  /// ```dart
  /// final sql = PgSql.map('SELECT * FROM users WHERE id = @id:int4');
  /// final stmt = await connection.prepare(sql);
  /// final vars = {'id': 3};
  /// await for (final row in stmt.bind(vars)) {
  ///   // Got user with id 3
  /// }
  /// ```
  ///
  /// String literals, identifiers and comments are correctly ignored. So for
  /// instance, the following query only uses one variable (`id`):
  ///
  /// ```sql
  /// SELECT name AS "@handle" FROM users WHERE id = @id; -- select @users
  /// ```
  ///
  /// Note that this syntax is a feature of this package and not directly
  /// understood by postgres. This requires the package to scan the [sql] for
  /// variables, which adds a small overhead over when compared to a direct
  /// [PgSql] query.
  /// Also, the scanner might interpret queries incorrectly in the case of
  /// malformed [sql] (like an unterminated string literal or comment). In that
  /// case, the transformation might not recognize all variables.
  factory PgSql.map(String sql, {String substitution}) =
      InternalQueryDescription.map;
}

abstract class PgSession {
  /// Prepares a reusable statement from a [query].
  ///
  /// Query can either be a string or a [PgSql] instance. The [query] value used
  /// alters the behavior of [PgStatement.bind]: When a string is used, the
  /// query is sent to Postgres without modification and you may only used
  /// indexed parameters (e.g. `SELECT * FROM users WHERE id = $1`). When using
  /// [PgSql.map], you can use named parameters as well (e.g. `WHERE id = @id`).
  ///
  /// When the returned future completes, the statement must eventually be freed
  /// using [PgStatement.close] to avoid resource leaks.
  Future<PgStatement> prepare(Object /* String | PgSql */ query);

  /// Executes the [query] with the given [parameters].
  ///
  /// [query] must either be a [String] or a [PgSql] query with types for
  /// parameters. When a [PgSql] query object with known types is used,
  /// [parameters] can be a list of direct values. Otherwise, it must be a list
  /// of [PgTypedParameter]s. With [PgSql.map], values can also be provided as a
  /// map from the substituted parameter keys to objects or [PgTypedParameter]s.
  ///
  /// When [ignoreRows] is set to true, the implementation may internally
  /// optimize the execution to ignore rows returned by the query. Whether this
  /// optimization can be applied also depends on the parameters chosen, so
  /// there is no guarantee that the [PgResult] from a [ignoreRows] excution has
  /// no rows.
  Future<PgResult> execute(
    Object /* String | PgSql */ query, {
    Object? /* List<Object?|PgTypedParameter> | Map<String, Object?|PgTypedParameter> */
        parameters,
    bool ignoreRows = false,
  });

  /// Closes this session, cleaning up resources and forbiding further calls to
  /// [prepare] and [execute].
  Future<void> close();
}

abstract class PgSessionExecutor {
  /// Obtains a [PgSession] capable of running statements and calls [fn] with
  /// it.
  ///
  /// Returns the result (either the value or an error) of invoking [fn]. No
  /// updates will be reverted in the event of an error.
  Future<R> run<R>(Future<R> Function(PgSession session) fn);

  /// Obtains a [PgSession] running in a transaction and calls [fn] with it.
  ///
  /// Returns the result of invoking [fn] (either the value or an error). In
  /// case of [fn] throwing, the transaction will be reverted.
  ///
  /// Note that other invocations on a [PgConnection] are blocked while a
  /// transaction is active.
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
      Object? /* List<Object?|PgTypedParameter> | Map<String, Object?|PgTypedParameter> */
          parameters);

  Future<PgResult> run([
    Object? /* List<Object?|PgTypedParameter> | Map<String, Object?|PgTypedParameter> */
        parameters,
  ]
  ) async {
    final items = <PgResultRow>[];
    final subscription = bind(parameters).listen(items.add);
    await subscription.asFuture();
    await subscription.cancel();

    return PgResult(
        items, await subscription.affectedRows, await subscription.schema);
  }

  Future<void> dispose();
}

final class PgTypedParameter {
  final PgDataType type;
  final Object? value;

  PgTypedParameter(this.type, this.value);

  @override
  String toString() {
    return 'PgTypedParameter($type, $value)';
  }

  @override
  int get hashCode => Object.hash(type, value);

  @override
  bool operator ==(Object other) {
    return other is PgTypedParameter &&
        other.type == type &&
        other.value == value;
  }
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

final class PgResultSchema {
  final List<PgResultColumn> columns;

  PgResultSchema(this.columns);

  @override
  String toString() {
    return 'PgResultSchema(${columns.join(', ')})';
  }
}

final class PgResultColumn {
  final PgDataType type;
  final String? tableName;
  final int? tableOid;
  final String? columnName;
  final int? columnOid;
  final bool binaryEncoding;

  PgResultColumn({
    required this.type,
    this.tableName,
    this.tableOid,
    this.columnName,
    this.columnOid,
    this.binaryEncoding = false,
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

final class PgEndpoint {
  final String host;
  final int port;
  final String database;
  final String? username;
  final String? password;
  final bool requireSsl;
  final bool isUnixSocket;

  /// Whether the client should send the password to the server in clear-text
  /// for authentication.
  ///
  /// For security reasons, it is recommended to keep this disabled.
  final bool allowCleartextPassword;

  PgEndpoint({
    required this.host,
    this.port = 5432,
    required this.database,
    this.username,
    this.password,
    this.requireSsl = false,
    this.isUnixSocket = false,
    this.allowCleartextPassword = false,
  });
}

final class PgSessionSettings {
  // Duration(seconds: 15)
  final Duration? connectTimeout;
  // Duration(minutes: 5)
  final String? timeZone;

  final bool Function(X509Certificate)? onBadSslCertificate;

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

  /// The replication mode for connecting in streaming replication mode.
  ///
  /// The default value is [ReplicationMode.none]. But when the value is set to 
  /// [ReplicationMode.physical] or [ReplicationMode.logical], the connection 
  /// will be established in replication mode.
  ///
  /// Please note, while in replication mode, only the Simple Query Protcol can
  /// be used to execute queries. 
  ///
  /// For more info, see [Streaming Replication Protocol]
  ///
  /// [Streaming Replication Protocol]: https://www.postgresql.org/docs/current/protocol-replication.html
  final ReplicationMode replicationMode;

  PgSessionSettings({
    this.connectTimeout,
    this.timeZone,
    this.onBadSslCertificate,
    this.transformer,
    this.replicationMode = ReplicationMode.none
  });
}

final class PgPoolSettings {
  final int? maxConnectionCount;

  const PgPoolSettings({
    this.maxConnectionCount,
  });
}
