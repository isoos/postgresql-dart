import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:stream_channel/stream_channel.dart';

import 'src/replication.dart';
import 'src/types.dart';
import 'src/v3/connection.dart';
import 'src/v3/protocol.dart';
import 'src/v3/query_description.dart';

export 'src/exceptions.dart';
export 'src/pool/pool_api.dart';
export 'src/replication.dart';
export 'src/types.dart';

/// A description of a SQL query as interpreted by this package.
///
/// This includes the SQL string to send to the database and known data types
/// for parameters, if any.
///
/// Queries can be sent to postgres as-is. To do that, pass a string to
/// [PgSession.prepare] or [PgSession.execute] or use the default [Sql]
/// constructor. These queries are not intepreted or altered by this package in
/// any way. If you're using parameter in those queries, you either have to
/// specify their types in the [Sql] constructor, or exclusively use
/// [TypedValue] instances in [PgSession.execute], [PgStatement.bind] and
/// [PgStatement.run].
///
/// Alternatively, you can use named variables that will be desugared by this
/// package with the [Sql.named] factory.
class Sql {
  /// The default constructor, sending [sql] to the Postgres database without
  /// any modification.
  ///
  /// The [types] parameter can optionally be used to pass the types of
  /// parameters in the query. If they're not set, only [TypedValue]
  /// instances can be used when binding values later.
  factory Sql(String sql, {List<DataType>? types}) =
      InternalQueryDescription.direct;

  /// Looks for named parameters in [sql] and desugars them.
  ///
  /// You can specify a character that starts parameters (by default, `@` is
  /// used).
  /// In those queries, `@variableName` can be used to declare a variable.
  ///
  /// ```dart
  /// final sql = Sql.named('SELECT * FROM users WHERE id = @id');
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
  /// final sql = Sql.named('SELECT * FROM users WHERE id = @id:int4');
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
  /// [Sql] query.
  /// Also, the scanner might interpret queries incorrectly in the case of
  /// malformed [sql] (like an unterminated string literal or comment). In that
  /// case, the transformation might not recognize all variables.
  factory Sql.named(String sql, {String substitution}) =
      InternalQueryDescription.named;
}

abstract class PgSession {
  /// Prepares a reusable statement from a [query].
  ///
  /// [query] must either be a [String] or a [Sql] object with types for
  /// parameters already set. If the types for parameters are already known from
  /// the query, a direct list of values can be passed for [parameters].
  /// Otherwise, the type of parameter types must be made explicit. This can be
  /// done by passing [TypedValue] objects in a list, or (if a string or
  /// [Sql.named] value is passed for [query]), via the names of declared
  /// statements.
  ///
  /// When the returned future completes, the statement must eventually be freed
  /// using [PgStatement.dispose] to avoid resource leaks.
  Future<PgStatement> prepare(Object /* String | Sql */ query);

  /// Executes the [query] with the given [parameters].
  ///
  /// [query] must either be a [String] or a [Sql] object with types for
  /// parameters already set. If the types for parameters are already known from
  /// the query, a direct list of values can be passed for [parameters].
  /// Otherwise, the type of parameter types must be made explicit. This can be
  /// done by passing [TypedValue] objects in a list, or (if a string or
  /// [Sql.named] value is passed for [query]), via the names of declared
  /// statements.
  ///
  /// When [ignoreRows] is set to true, the implementation may internally
  /// optimize the execution to ignore rows returned by the query. Whether this
  /// optimization can be applied also depends on the parameters chosen, so
  /// there is no guarantee that the [PgResult] from a [ignoreRows] excution has
  /// no rows.
  ///
  /// [queryMode] is optional to override the default query execution mode that
  /// is defined in [PgSessionSettings]. Unless necessary, always prefer using
  /// [QueryMode.extended] which is the default value. For more information,
  /// see [PgSessionSettings.queryMode]
  Future<PgResult> execute(
    Object /* String | Sql */ query, {
    Object? /* List<Object?|PgTypedParameter> | Map<String, Object?|PgTypedParameter> */
        parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  });
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

  /// Closes this session, cleaning up resources and forbiding further calls to
  /// [prepare] and [execute].
  Future<void> close();
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

  Future<PgResult> run(
    Object? /* List<Object?|PgTypedParameter> | Map<String, Object?|PgTypedParameter> */
        parameters, {
    Duration? timeout,
  }) async {
    final items = <PgResultRow>[];
    final subscription = bind(parameters).listen(items.add);
    await subscription.asFuture().optionalTimeout(timeout);
    await subscription.cancel();

    return PgResult(
        items, await subscription.affectedRows, await subscription.schema);
  }

  Future<void> dispose();
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

  /// Returns a single-level map that maps the column name (or its alias) to the
  /// value returned on that position. Multiple column with the same name may
  /// override the previous values.
  Map<String, dynamic> toColumnMap();
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
  final DataType type;
  final int? tableOid;
  final String? columnName;
  final int? columnOid;
  final bool binaryEncoding;

  PgResultColumn({
    required this.type,
    this.tableOid,
    this.columnName,
    this.columnOid,
    this.binaryEncoding = false,
  });

  @override
  String toString() {
    final buffer = StringBuffer('${type.name} ');
    if (tableOid != null && tableOid != 0) {
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
  /// A stream of all notifications delivered from the server.
  ///
  /// This stream can be used to listen to notifications manually subscribed to.
  /// The `[]` operator on [PgChannels] can be used to register subscriptions to
  /// notifications only when a stream is being listened to.
  Stream<PgNotification> get all;

  Stream<String> operator [](String channel);
  Future<void> notify(String channel, [String? payload]);
  Future<void> cancelAll();
}

typedef PgNotification = ({int processId, String channel, String payload});

final class PgEndpoint {
  final String host;
  final int port;
  final String database;
  final String? username;
  final String? password;
  final bool isUnixSocket;

  PgEndpoint({
    required this.host,
    this.port = 5432,
    required this.database,
    this.username,
    this.password,
    this.isUnixSocket = false,
  });

  @override
  int get hashCode => Object.hash(
        host,
        port,
        database,
        username,
        password,
        isUnixSocket,
      );

  @override
  bool operator ==(Object other) {
    return other is PgEndpoint &&
        host == other.host &&
        port == other.port &&
        database == other.database &&
        username == other.username &&
        password == other.password &&
        isUnixSocket == other.isUnixSocket;
  }
}

enum SslMode {
  /// No SSL is used, implies that password may be sent as plaintext.
  disable,

  /// Always use SSL (but ignore verification errors).
  require,

  /// Always use SSL and verify certificates.
  verifyFull,
  ;

  bool get ignoreCertificateIssues => this == SslMode.require;
  bool get allowCleartextPassword => this == SslMode.disable;
}

final class PgSessionSettings {
  // Duration(seconds: 15)
  final Duration? connectTimeout;
  // Duration(minutes: 5)
  final String? timeZone;

  final Encoding? encoding;

  final SslMode? sslMode;

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
  final StreamChannelTransformer<Message, Message>? transformer;

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

  /// The Query Execution Mode
  ///
  /// The default value is [QueryMode.extended] which uses the Extended Query
  /// Protocol. In certain cases, the Extended protocol cannot be used
  /// (e.g. in replication mode or with proxies such as PGBouncer), hence the
  /// the Simple one would be the only viable option. Unless necessary, always
  /// prefer using [QueryMode.extended].
  final QueryMode queryMode;

  /// Override the default query map check if superfluous parameters are found.
  final bool? allowSuperfluousParameters;

  PgSessionSettings({
    this.connectTimeout,
    this.timeZone,
    this.encoding,
    this.sslMode,
    this.transformer,
    this.replicationMode = ReplicationMode.none,
    this.queryMode = QueryMode.extended,
    this.allowSuperfluousParameters,
  });
}

/// Options for the Query Execution Mode
enum QueryMode {
  /// Extended Query Protocol
  extended,

  /// Simple Query Protocol
  simple,
}
