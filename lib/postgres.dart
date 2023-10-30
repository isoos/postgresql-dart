import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
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
/// [Session.prepare] or [Session.execute] or use the default [Sql]
/// constructor. These queries are not intepreted or altered by this package in
/// any way. If you're using parameter in those queries, you either have to
/// specify their types in the [Sql] constructor, or exclusively use
/// [TypedValue] instances in [Session.execute], [Statement.bind] and
/// [Statement.run].
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
  factory Sql(String sql, {List<Type>? types}) =
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
  /// final vars = {'id': TypedValue(Type.integer, 3)};
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

abstract class Session {
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
  /// using [Statement.dispose] to avoid resource leaks.
  Future<Statement> prepare(Object /* String | Sql */ query);

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
  /// there is no guarantee that the [Result] from a [ignoreRows] excution has
  /// no rows.
  ///
  /// [queryMode] is optional to override the default query execution mode that
  /// is defined in [SessionSettings]. Unless necessary, always prefer using
  /// [QueryMode.extended] which is the default value. For more information,
  /// see [SessionSettings.queryMode]
  Future<Result> execute(
    Object /* String | Sql */ query, {
    Object? /* List<Object?|TypedValue> | Map<String, Object?|TypedValue> */
        parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  });
}

abstract class SessionExecutor {
  /// Obtains a [Session] capable of running statements and calls [fn] with
  /// it.
  ///
  /// Returns the result (either the value or an error) of invoking [fn]. No
  /// updates will be reverted in the event of an error.
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    SessionSettings? settings,
  });

  /// Obtains a [Session] running in a transaction and calls [fn] with it.
  ///
  /// Returns the result of invoking [fn] (either the value or an error). In
  /// case of [fn] throwing, the transaction will be reverted.
  ///
  /// Note that other invocations on a [Connection] are blocked while a
  /// transaction is active.
  Future<R> runTx<R>(
    Future<R> Function(Session session) fn, {
    TransactionSettings? settings,
  });

  /// Closes this session, cleaning up resources and forbiding further calls to
  /// [prepare] and [execute].
  Future<void> close();
}

abstract class Connection implements Session, SessionExecutor {
  static Future<Connection> open(
    Endpoint endpoint, {
    ConnectionSettings? settings,
  }) {
    return PgConnectionImplementation.connect(endpoint,
        connectionSettings: settings);
  }

  Channels get channels;
}

abstract class ResultStream implements Stream<ResultRow> {
  @override
  ResultStreamSubscription listen(
    void Function(ResultRow event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  });
}

abstract class ResultStreamSubscription
    implements StreamSubscription<ResultRow> {
  Future<int> get affectedRows;
  Future<ResultSchema> get schema;
}

abstract class Statement {
  ResultStream bind(
      Object? /* List<Object?|TypedValue> | Map<String, Object?|TypedValue> */
          parameters);

  Future<Result> run(
    Object? /* List<Object?|TypedValue> | Map<String, Object?|TypedValue> */
        parameters, {
    Duration? timeout,
  });

  Future<void> dispose();
}

class Result extends UnmodifiableListView<ResultRow> {
  final int affectedRows;
  final ResultSchema schema;

  Result({
    required List<ResultRow> rows,
    required this.affectedRows,
    required this.schema,
  }) : super(rows);
}

class ResultRow extends UnmodifiableListView<Object?> {
  final ResultSchema schema;

  ResultRow({
    required List<Object?> values,
    required this.schema,
  }) : super(values);

  /// Returns a single-level map that maps the column name to the value
  /// returned on that position. When multiple columns have the same name,
  /// the later may override the previous values.
  Map<String, dynamic> toColumnMap() {
    final map = <String, dynamic>{};
    for (final (i, col) in schema.columns.indexed) {
      if (col.columnName case final String name) {
        map[name] = this[i];
      } else {
        map['[$i]'] = this[i];
      }
    }
    return map;
  }
}

final class ResultSchema {
  final List<ResultSchemaColumn> columns;

  ResultSchema(this.columns);

  @override
  String toString() {
    return 'ResultSchema(${columns.join(', ')})';
  }
}

final class ResultSchemaColumn {
  final Type type;
  final int? tableOid;
  final String? columnName;
  final int? columnOid;
  final bool isBinaryEncoding;

  ResultSchemaColumn({
    required this.type,
    this.tableOid,
    this.columnName,
    this.columnOid,
    this.isBinaryEncoding = false,
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

abstract class Channels {
  /// A stream of all notifications delivered from the server.
  ///
  /// This stream can be used to listen to notifications manually subscribed to.
  /// The `[]` operator on [Channels] can be used to register subscriptions to
  /// notifications only when a stream is being listened to.
  Stream<Notification> get all;

  Stream<String> operator [](String channel);
  Future<void> notify(String channel, [String? payload]);
  Future<void> cancelAll();
}

/// Represents a notification from the Postgresql server.
class Notification {
  /// The Postgresql process ID from which the notification was generated.
  final int processId;

  /// The name of the channel that this notification occurred on.
  final String channel;

  /// An optional data payload accompanying this notification.
  final String payload;

  Notification({
    required this.processId,
    required this.channel,
    required this.payload,
  });
}

final class Endpoint {
  final String host;
  final int port;
  final String database;
  final String? username;
  final String? password;
  final bool isUnixSocket;

  Endpoint({
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
    return other is Endpoint &&
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

class ConnectionSettings extends SessionSettings {
  final String? applicationName;
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
  final ReplicationMode? replicationMode;

  ConnectionSettings({
    this.applicationName,
    this.timeZone,
    this.encoding,
    this.sslMode,
    this.transformer,
    this.replicationMode,
    super.connectTimeout,
    super.queryTimeout,
    super.queryMode,
    super.allowSuperfluousParameters,
  });
}

class SessionSettings {
  // Duration(seconds: 15)
  final Duration? connectTimeout;

  // Duration(minutes: 5)
  final Duration? queryTimeout;

  /// The Query Execution Mode
  ///
  /// The default value is [QueryMode.extended] which uses the Extended Query
  /// Protocol. In certain cases, the Extended protocol cannot be used
  /// (e.g. in replication mode or with proxies such as PGBouncer), hence the
  /// the Simple one would be the only viable option. Unless necessary, always
  /// prefer using [QueryMode.extended].
  final QueryMode? queryMode;

  /// Override the default query map check if superfluous parameters are found.
  final bool? allowSuperfluousParameters;

  SessionSettings({
    this.connectTimeout,
    this.queryTimeout,
    this.queryMode,
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

/// The isolation level of a transaction determines what data the transaction
/// can see when other transactions are running concurrently.
enum IsolationLevel {
  /// A statement can only see rows committed before it began.
  /// This is the default.
  readCommitted._('READ COMMITTED'),

  /// All statements of the current transaction can only see rows committed
  /// before the first query or data-modification statement was executed in
  /// this transaction.
  repeatableRead._('REPEATABLE READ'),

  /// All statements of the current transaction can only see rows committed
  /// before the first query or data-modification statement was executed in
  /// this transaction. If a pattern of reads and writes among concurrent
  /// serializable transactions would create a situation which could not have
  /// occurred for any serial (one-at-a-time) execution of those transactions,
  /// one of them will be rolled back with a serialization_failure error.
  serializable._('SERIALIZABLE'),

  /// One transaction may see uncommitted changes made by some other transaction.
  /// In PostgreSQL READ UNCOMMITTED is treated as READ COMMITTED.
  readUncommitted._('READ UNCOMMITTED'),
  ;

  /// The SQL identifier of the isolation level including "ISOLATION LEVEL" prefix
  /// and leading space.
  @internal
  final String queryPart;

  const IsolationLevel._(String value) : queryPart = ' ISOLATION LEVEL $value';
}

/// The transaction access mode determines whether the transaction is read/write
/// or read-only.
enum AccessMode {
  /// Read/write is the default.
  readWrite._('READ WRITE'),

  /// When a transaction is read-only, the following SQL commands are disallowed:
  /// INSERT, UPDATE, DELETE, MERGE, and COPY FROM if the table they would write
  /// to is not a temporary table; all CREATE, ALTER, and DROP commands; COMMENT,
  /// GRANT, REVOKE, TRUNCATE; and EXPLAIN ANALYZE and EXECUTE if the command
  /// they would execute is among those listed. This is a high-level notion of
  /// read-only that does not prevent all writes to disk.
  readOnly._('READ ONLY'),
  ;

  /// The SQL identifier of the access mode including leading space.
  @internal
  final String queryPart;

  const AccessMode._(String value) : queryPart = ' $value';
}

/// The deferrable mode of the transaction.
enum DeferrableMode {
  /// The DEFERRABLE transaction property has no effect unless the transaction
  /// is also SERIALIZABLE and READ ONLY. When all three of these properties
  /// are selected for a transaction, the transaction may block when first
  /// acquiring its snapshot, after which it is able to run without the normal
  /// overhead of a SERIALIZABLE transaction and without any risk of contributing
  /// to or being canceled by a serialization failure. This mode is well suited
  /// for long-running reports or backups.
  deferrable._('DEFERRABLE'),

  /// The default mode.
  notDeferrable._('NOT DEFERRABLE'),
  ;

  /// The SQL identifier of the deferrable mode including leading space.
  @internal
  final String queryPart;

  const DeferrableMode._(String value) : queryPart = ' $value';
}

/// The characteristics of the current transaction.
class TransactionSettings extends SessionSettings {
  /// The isolation level of a transaction determines what data the transaction
  /// can see when other transactions are running concurrently.
  final IsolationLevel? isolationLevel;

  /// The transaction access mode determines whether the transaction is read/write
  /// or read-only.
  final AccessMode? accessMode;

  /// The DEFERRABLE transaction property has no effect unless the transaction
  /// is also SERIALIZABLE and READ ONLY. When all three of these properties
  /// are selected for a transaction, the transaction may block when first
  /// acquiring its snapshot, after which it is able to run without the normal
  /// overhead of a SERIALIZABLE transaction and without any risk of contributing
  /// to or being canceled by a serialization failure. This mode is well suited
  /// for long-running reports or backups.
  final DeferrableMode? deferrable;

  TransactionSettings({
    this.isolationLevel,
    this.accessMode,
    this.deferrable,
    super.connectTimeout,
    super.queryTimeout,
    super.queryMode,
    super.allowSuperfluousParameters,
  });
}
