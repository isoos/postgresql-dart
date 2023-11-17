library postgres.connection;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../../postgres.dart' show ConnectionSettings, Endpoint, Notification;
import '../exceptions.dart';
import '../messages/client_messages.dart';
import '../messages/server_messages.dart';
import '../replication.dart';
import 'execution_context.dart';
import 'v2_v3_delegate.dart';

part 'transaction_proxy.dart';

typedef PostgreSQLException = ServerException;

/// Instances of this class connect to and communicate with a PostgreSQL database.
///
/// The primary type of this library, a connection is responsible for connecting to databases and executing queries.
/// A connection may be opened with [open] after it is created.
@Deprecated('Do not use v2 API, will be removed in next release.')
abstract class PostgreSQLConnection implements PostgreSQLExecutionContext {
  /// Returns a somewhat compatible version of [PostgreSQLConnection]
  /// that is backed by the new v3 implementation.
  static PostgreSQLConnection withV3(
    Endpoint endpoint, {
    ConnectionSettings? connectionSettings,
  }) {
    return WrappedPostgreSQLConnection(
        endpoint, connectionSettings ?? ConnectionSettings());
  }

  final StreamController<Notification> _notifications =
      StreamController<Notification>.broadcast();

  final StreamController<ServerMessage> _messages =
      StreamController<ServerMessage>.broadcast();

  /// Hostname of database this connection refers to.
  String get host;

  /// Port of database this connection refers to.
  int get port;

  /// Name of database this connection refers to.
  String get databaseName;

  /// Username for authenticating this connection.
  String? get username;

  /// Password for authenticating this connection.
  String? get password;

  /// Whether or not this connection should connect securely.
  bool get useSSL;

  /// The amount of time this connection will wait during connecting before giving up.
  int get timeoutInSeconds;

  /// The default timeout for [PostgreSQLExecutionContext]'s execute and query methods.
  int get queryTimeoutInSeconds;

  /// The timezone of this connection for date operations that don't specify a timezone.
  String get timeZone;

  /// The processID of this backend.
  int get processID => _processID;

  /// If true, connection is made via unix socket.
  bool get isUnixSocket;

  /// If true, allows password in clear text for authentication.
  bool get allowClearTextPassword;

  /// The replication mode for connecting in streaming replication mode.
  ///
  /// When the value is set to either [ReplicationMode.physical] or [ReplicationMode.logical],
  /// the query protocol will no longer work as the connection will be switched to a replication
  /// connection. In other words, using the default [query] or [mappedResultsQuery] will cause
  /// the database to throw an error and drop the connection.
  ///
  /// Use [query] `useSimpleQueryProtocol` set to `true` or [execute] for executing statements
  /// while in replication mode.
  ///
  /// For more info, see [Streaming Replication Protocol]
  ///
  /// [Streaming Replication Protocol]: https://www.postgresql.org/docs/current/protocol-replication.html
  ReplicationMode get replicationMode;

  /// Stream of notification from the database.
  ///
  /// Listen to this [Stream] to receive events from PostgreSQL NOTIFY commands.
  ///
  /// To determine whether or not the NOTIFY came from this instance, compare [processID]
  /// to [Notification.processId].
  Stream<Notification> get notifications => _notifications.stream;

  /// Stream of server messages
  ///
  /// Listen to this [Stream] to receive events for all PostgreSQL server messages
  ///
  /// This includes all messages whether from Extended Query Protocol, Simple Query Protocol
  /// or Streaming Replication Protocol.
  Stream<ServerMessage> get messages => _messages.stream;

  /// Reports on the latest known status of the connection: whether it was open or failed for some reason.
  ///
  /// This is `true` when this instance is first created and after it has been closed or encountered an unrecoverable error.
  /// If a connection has already been opened and this value is now true, the connection cannot be reopened and a instance
  /// must be created.
  bool get isClosed;

  /// Settings values from the connected database.
  ///
  /// After connecting to a database, this map will contain the settings values that the database returns.
  /// Prior to connection, it is the empty map.
  final Map<String, String> settings = {};

  Socket? _socket;
  late int _processID;
  // ignore: unused_field
  late int _secretKey;

  Socket? get socket => _socket;

  Encoding get _encoding;
  @internal
  Encoding get encoding => _encoding;

  /// Establishes a connection with a PostgreSQL database.
  ///
  /// This method will return a [Future] that completes when the connection is established. Queries can be executed
  /// on this connection afterwards. If the connection fails to be established for any reason - including authentication -
  /// the returned [Future] will return with an error.
  ///
  /// Connections may not be reopened after they are closed or opened more than once. If a connection has already been
  /// opened and this method is called, an exception will be thrown.
  Future open();

  /// Closes a connection.
  ///
  /// After the returned [Future] completes, this connection can no longer be used to execute queries. Any queries in progress or queued are cancelled.
  Future close();

  /// Adds a Client Message to the existing connection
  ///
  /// This is a low level API and the message must follow the protocol of this
  /// connection. It's the responsiblity of the caller to ensure this message
  /// does not interfere with any running queries or transactions.
  void addMessage(ClientMessage message) {
    if (isClosed) {
      throw PgException(
          'Attempting to add a message, but connection is not open.');
    }
    _socket!.add(message.asBytes(encoding: encoding));
  }

  /// Executes a series of queries inside a transaction on this connection.
  ///
  /// Queries executed inside [queryBlock] will be grouped together in a transaction. The return value of the [queryBlock]
  /// will be the wrapped in the [Future] returned by this method if the transaction completes successfully.
  ///
  /// If a query or execution fails - for any reason - within a transaction block,
  /// the transaction will fail and previous statements within the transaction will not be committed. The [Future]
  /// returned from this method will be completed with the error from the first failing query.
  ///
  /// Transactions may be cancelled by invoking [PostgreSQLExecutionContext.cancelTransaction]
  /// within the transaction. This will cause this method to return a [Future] with a value of [PostgreSQLRollback]. This method does not throw an exception
  /// if the transaction is cancelled in this way.
  ///
  /// All queries within a transaction block must be executed using the [PostgreSQLExecutionContext] passed into the [queryBlock].
  /// You must not issue queries to the receiver of this method from within the [queryBlock], otherwise the connection will deadlock.
  ///
  /// Queries within a transaction may be executed asynchronously or be awaited on. The order is still guaranteed. Example:
  ///
  ///         connection.transaction((ctx) {
  ///           var rows = await ctx.query("SELECT id FROM t");
  ///           if (!rows.contains([2])) {
  ///             ctx.query("INSERT INTO t (id) VALUES (2)");
  ///           }
  ///         });
  ///
  /// If specified, the final `"COMMIT"` query of the transaction will use
  /// [commitTimeoutInSeconds] as its timeout, otherwise the connection's
  /// default query timeout will be used.
  Future transaction(
    Future Function(PostgreSQLExecutionContext connection) queryBlock, {
    int? commitTimeoutInSeconds,
  });

  @override
  void cancelTransaction({String? reason}) {
    // Default is no-op
  }
}
