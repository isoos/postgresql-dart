import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import 'src/replication.dart';
import 'src/types.dart';
import 'src/types/type_registry.dart';
import 'src/v3/connection.dart';
import 'src/v3/protocol.dart';
import 'src/v3/query_description.dart';

export 'src/exceptions.dart';
export 'src/pool/pool_api.dart';
export 'src/replication.dart';
export 'src/types.dart';
export 'src/types/geo_types.dart';
export 'src/types/range_types.dart';
export 'src/types/text_search.dart'
    show TsVector, TsWord, TsWordPos, TsWeight, TsQuery;
export 'src/types/type_registry.dart' show TypeRegistry;

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
/// package with the [Sql.named] factory. If you prefer positional variables,
/// but want to specify their types in text or use a different symbol for
/// variables (Postgres uses `$`), you can use the [Sql.indexed] constructor
/// instead.
class Sql {
  /// The default constructor, sending [sql] to the Postgres database without
  /// any modification.
  ///
  /// The [types] parameter can optionally be used to pass the types of
  /// parameters in the query. If they're not set, only [TypedValue]
  /// instances can be used when binding values later.
  factory Sql(String sql, {List<Type>? types}) = SqlImpl.direct;

  /// Looks for positional parameters in [sql] and desugars them.
  ///
  /// This mode is very similar to the native format understood by postgres,
  /// except that:
  ///  1. The character for variables is customizable (postgres will always use
  ///     `$`). To be consistent with [Sql.named], this method uses `@` as the
  ///     default character.
  ///  2. Not every variable needs to have en explicit index. When declaring a
  ///     variable without an index, the first index higher than any previously
  ///     seen index is used instead.
  ///
  /// For instance, `Sql.indexed('SELECT ?2, ?, ?1', substitution: '?')`
  /// declares three variables (appearing in the order 2, 3, 1).
  ///
  /// Just like with [Sql.named], it is possible to declare an explicit type for
  /// variables: `Sql.indexed('SELECT @1:int8')`.
  factory Sql.indexed(String sql, {String substitution}) = SqlImpl.indexed;

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
  factory Sql.named(String sql, {String substitution}) = SqlImpl.named;
}

abstract class Session {
  /// Whether this connection is currently open.
  ///
  /// A [Connection] is open until it's closed (either by an explicit
  /// [Connection.close] call or due to an unrecoverable error from the server).
  /// Other sessions, such as transactions or connections borrowed from a pool,
  /// may have a shorter lifetime.
  ///
  /// The [closed] future can be awaited to get notified when this session is
  /// closing.
  bool get isOpen;

  /// A future that completes when [isOpen] turns false.
  Future<void> get closed;

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

/// A [Session] with transaction-related helper method(s).
abstract class TxSession extends Session {
  /// Executes `ROLLBACK` and closes the transaction session.
  /// Further queries will throw an exception.
  Future<void> rollback();
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
    Future<R> Function(TxSession session) fn, {
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
  final int typeOid;
  final Type type;
  final int? tableOid;
  final String? columnName;
  final int? columnOid;
  final bool isBinaryEncoding;

  ResultSchemaColumn({
    required this.typeOid,
    required this.type,
    this.tableOid,
    this.columnName,
    this.columnOid,
    this.isBinaryEncoding = false,
  });

  @override
  String toString() {
    final buffer = StringBuffer('$type ');
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
  ///
  /// If you're using this option to accept self-signed certificates, consider
  /// the security ramifications of accepting _every_ certificate: Despite using
  /// TLS, MitM attacks are possible by injecting another certificate.
  /// An alternative is using [verifyFull] with a [SecurityContext] passed to
  /// [ConnectionSettings.securityContext] that only accepts the known
  /// self-signed certificate.
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

  /// The [SecurityContext] to use when opening a connection.
  ///
  /// This can be configured to only allow some certificates. When used,
  /// [ConnectionSettings.sslMode] should be set to [SslMode.verifyFull], as
  /// this package will allow other certificates or insecure connections
  /// otherwise.
  final SecurityContext? securityContext;

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

  /// When set, use the type registry with custom types, instead of the
  /// built-in ones provided by the package.
  final TypeRegistry? typeRegistry;

  /// This callback function will be called after opening the connection.
  final Future<void> Function(Connection connection)? onOpen;

  const ConnectionSettings({
    this.applicationName,
    this.timeZone,
    this.encoding,
    this.sslMode,
    this.transformer,
    this.replicationMode,
    this.typeRegistry,
    this.securityContext,
    this.onOpen,
    super.connectTimeout,
    super.queryTimeout,
    super.queryMode,
    super.ignoreSuperfluousParameters,
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

  /// When set, the default query map will not throw exception when superfluous
  /// parameters are found.
  final bool? ignoreSuperfluousParameters;

  const SessionSettings({
    this.connectTimeout,
    this.queryTimeout,
    this.queryMode,
    this.ignoreSuperfluousParameters,
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

/// The settings that control the retry of [SessionExecutor.run] and [SessionExecutor.runTx] methods.
class Retry<R> {
  /// The maximum number of attempts to run the operation.
  final int maxAttempts;

  final FutureOr<R> Function()? orElse;
  final FutureOr<bool> Function(Exception)? retryIf;

  Retry({
    required this.maxAttempts,
    this.orElse,
    this.retryIf,
  });
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
    super.ignoreSuperfluousParameters,
  });
}
