library postgres.connection;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:meta/meta.dart';

import 'auth/auth.dart';
import 'client_messages.dart';
import 'execution_context.dart';
import 'message_window.dart';
import 'placeholder_identifier_enum.dart';
import 'query.dart';
import 'query_cache.dart';
import 'query_queue.dart';
import 'replication.dart';
import 'server_messages.dart';

part 'connection_fsm.dart';
part 'exceptions.dart';
part 'transaction_proxy.dart';

/// Instances of this class connect to and communicate with a PostgreSQL database.
///
/// The primary type of this library, a connection is responsible for connecting to databases and executing queries.
/// A connection may be opened with [open] after it is created.
class PostgreSQLConnection extends Object
    with _PostgreSQLExecutionContextMixin
    implements PostgreSQLExecutionContext {
  /// Creates an instance of [PostgreSQLConnection].
  ///
  /// [host] must be a hostname, e.g. "foobar.com" or IP address. Do not include scheme or port.
  /// [port] is the port to connect to the database on. It is typically 5432 for default PostgreSQL settings.
  /// [databaseName] is the name of the database to connect to.
  /// [username] and [password] are optional if the database requires user authentication.
  /// [timeoutInSeconds] refers to the amount of time [PostgreSQLConnection] will wait while establishing a connection before it gives up.
  /// [queryTimeoutInSeconds] refers to the default timeout for [PostgreSQLExecutionContext]'s execute and query methods.
  /// [timeZone] is the timezone the connection is in. Defaults to 'UTC'.
  /// [useSSL] when true, uses a secure socket when connecting to a PostgreSQL database.
  /// [allowClearTextPassword] when true, allows sending the password during authentication in clear text. Use only when required by the database server and under encrypted connections, this feature may lead to security issues.
  PostgreSQLConnection(
    this.host,
    this.port,
    this.databaseName, {
    this.encoding = utf8,
    this.username,
    this.password,
    this.timeoutInSeconds = 30,
    this.queryTimeoutInSeconds = 30,
    this.timeZone = 'UTC',
    this.useSSL = false,
    this.isUnixSocket = false,
    this.allowClearTextPassword = false,
    this.replicationMode = ReplicationMode.none,
  }) {
    _connectionState = _PostgreSQLConnectionStateClosed();
    _connectionState.connection = this;
  }

  final StreamController<Notification> _notifications =
      StreamController<Notification>.broadcast();

  final StreamController<ServerMessage> _messages =
      StreamController<ServerMessage>.broadcast();

  /// Hostname of database this connection refers to.
  final String host;

  /// Port of database this connection refers to.
  final int port;

  /// Name of database this connection refers to.
  final String databaseName;

  /// Username for authenticating this connection.
  final String? username;

  /// Password for authenticating this connection.
  final String? password;

  /// Whether or not this connection should connect securely.
  final bool useSSL;

  /// The amount of time this connection will wait during connecting before giving up.
  final int timeoutInSeconds;

  /// The default timeout for [PostgreSQLExecutionContext]'s execute and query methods.
  final int queryTimeoutInSeconds;

  /// The timezone of this connection for date operations that don't specify a timezone.
  final String timeZone;

  /// The processID of this backend.
  int get processID => _processID;

  /// If true, connection is made via unix socket.
  final bool isUnixSocket;

  /// If true, allows password in clear text for authentication.
  final bool allowClearTextPassword;

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
  final ReplicationMode replicationMode;

  /// Stream of notification from the database.
  ///
  /// Listen to this [Stream] to receive events from PostgreSQL NOTIFY commands.
  ///
  /// To determine whether or not the NOTIFY came from this instance, compare [processID]
  /// to [Notification.processID].
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
  bool get isClosed => _connectionState is _PostgreSQLConnectionStateClosed;

  /// Settings values from the connected database.
  ///
  /// After connecting to a database, this map will contain the settings values that the database returns.
  /// Prior to connection, it is the empty map.
  final Map<String, String> settings = {};

  final _cache = QueryCache();
  final _oidCache = _OidCache();
  Socket? _socket;
  late MessageFramer _framer;
  late int _processID;
  // ignore: unused_field
  late int _secretKey;

  bool _hasConnectedPreviously = false;
  late _PostgreSQLConnectionState _connectionState;

  @override
  PostgreSQLExecutionContext get _transaction => this;

  @override
  PostgreSQLConnection get _connection => this;

  Socket? get socket => _socket;

  /// dataBase charset
  final Encoding encoding;

  /// Establishes a connection with a PostgreSQL database.
  ///
  /// This method will return a [Future] that completes when the connection is established. Queries can be executed
  /// on this connection afterwards. If the connection fails to be established for any reason - including authentication -
  /// the returned [Future] will return with an error.
  ///
  /// Connections may not be reopened after they are closed or opened more than once. If a connection has already been
  /// opened and this method is called, an exception will be thrown.
  Future open() async {
    if (_hasConnectedPreviously) {
      throw PostgreSQLException(
          'Attempting to reopen a closed connection. Create a instance instead.');
    }

    try {
      _hasConnectedPreviously = true;
      if (isUnixSocket) {
        _socket = await Socket.connect(
                InternetAddress(host, type: InternetAddressType.unix), port)
            .timeout(Duration(seconds: timeoutInSeconds));
      } else {
        _socket = await Socket.connect(host, port)
            .timeout(Duration(seconds: timeoutInSeconds));
      }

      _framer = MessageFramer(encoding);
      if (useSSL) {
        _socket =
            await _upgradeSocketToSSL(_socket!, timeout: timeoutInSeconds);
      }

      final connectionComplete = Completer();
      _socket!.listen(_readData, onError: _close, onDone: _close);

      _transitionToState(
          _PostgreSQLConnectionStateSocketConnected(connectionComplete));

      await connectionComplete.future
          .timeout(Duration(seconds: timeoutInSeconds));
    } on TimeoutException catch (e, st) {
      final err = PostgreSQLException(
          'Failed to connect to database $host:$port/$databaseName failed to connect.');
      await _close(err, st);
      rethrow;
    } catch (e, st) {
      await _close(e, st);

      rethrow;
    }
  }

  /// Closes a connection.
  ///
  /// After the returned [Future] completes, this connection can no longer be used to execute queries. Any queries in progress or queued are cancelled.
  Future close() => _close();

  /// Adds a Client Message to the existing connection
  ///
  /// This is a low level API and the message must follow the protocol of this
  /// connection. It's the responsiblity of the caller to ensure this message
  /// does not interfere with any running queries or transactions.
  void addMessage(ClientMessage message) {
    if (isClosed) {
      throw PostgreSQLException(
          'Attempting to add a message, but connection is not open.');
    }
    _socket!.add(message.asBytes());
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
  }) async {
    if (isClosed) {
      throw PostgreSQLException(
          'Attempting to execute query, but connection is not open.');
    }

    final proxy = _TransactionProxy(this, queryBlock, commitTimeoutInSeconds);

    await _enqueue(proxy._beginQuery);

    return await proxy.future;
  }

  @override
  void cancelTransaction({String? reason}) {
    // Default is no-op
  }

  ////////

  void _transitionToState(_PostgreSQLConnectionState newState) {
    if (identical(newState, _connectionState)) {
      return;
    }

    _connectionState.onExit();

    _connectionState = newState;
    _connectionState.connection = this;

    _transitionToState(_connectionState.onEnter());
  }

  Future _close([dynamic error, StackTrace? trace]) async {
    _connectionState = _PostgreSQLConnectionStateClosed();

    if (_socket != null) {
      await _socket!.close();
    }
    await _notifications.close();

    await _messages.close();

    _queue.cancel(error, trace);
  }

  void _readData(List<int> bytes) {
    // Note that the way this method works, if a query is in-flight, and we move to the closed state
    // manually, the delivery of the bytes from the socket is sent to the 'Closed State',
    // and the state node managing delivering data to the query no longer exists. Therefore,
    // as soon as a close occurs, we detach the data stream from anything that actually does
    // anything with that data.
    _framer.addBytes(castBytes(bytes));
    while (_framer.hasMessage) {
      final msg = _framer.popMessage();
      try {
        if (_messages.hasListener) {
          _messages.add(msg);
        }
        if (msg is ErrorResponseMessage) {
          _transitionToState(_connectionState.onErrorResponse(msg));
        } else if (msg is NotificationResponseMessage) {
          _notifications
              .add(Notification(msg.processID, msg.channel, msg.payload));
        } else {
          _transitionToState(_connectionState.onMessage(msg));
        }
      } catch (e, st) {
        _close(e, st);
      }
    }
  }

  Future<Socket> _upgradeSocketToSSL(Socket originalSocket,
      {int timeout = 30}) {
    final sslCompleter = Completer<int>();

    originalSocket.listen((data) {
      if (data.length != 1) {
        sslCompleter.completeError(PostgreSQLException(
            'Could not initialize SSL connection, received unknown byte stream.'));
        return;
      }

      sslCompleter.complete(data.first);
    },
        onDone: () => sslCompleter.completeError(PostgreSQLException(
            'Could not initialize SSL connection, connection closed during handshake.')),
        onError: sslCompleter.completeError);

    final byteBuffer = ByteData(8);
    byteBuffer.setUint32(0, 8);
    byteBuffer.setUint32(4, 80877103);
    originalSocket.add(byteBuffer.buffer.asUint8List());

    return sslCompleter.future
        .timeout(Duration(seconds: timeout))
        .then((responseByte) {
      if (responseByte != 83) {
        throw PostgreSQLException(
            'The database server is not accepting SSL connections.');
      }

      return SecureSocket.secure(originalSocket,
              onBadCertificate: (certificate) => true)
          .timeout(Duration(seconds: timeout));
    });
  }
}

class _TransactionRollbackException implements Exception {
  _TransactionRollbackException(this.reason);

  String reason;
}

/// Represents a notification from PostgreSQL.
///
/// Instances of this type are created and sent via [PostgreSQLConnection.notifications].
class Notification {
  /// Creates an instance of this type.
  Notification(this.processID, this.channel, this.payload);

  /// The backend ID from which the notification was generated.
  final int processID;

  /// The name of the PostgreSQL channel that this notification occurred on.
  final String channel;

  /// An optional data payload accompanying this notification.
  final String payload;
}

class _OidCache {
  final _tableOIDNameMap = <int, String>{};
  int _queryCount = 0;

  int get queryCount => _queryCount;

  void clear() {
    _queryCount = 0;
    _tableOIDNameMap.clear();
  }

  Future<List<FieldDescription>> _resolveTableNames(
      _PostgreSQLExecutionContextMixin c,
      List<FieldDescription?>? columns) async {
    if (columns == null) return [];
    //todo (joeconwaystk): If this was a cached query, resolving is table oids is unnecessary.
    // It's not a significant impact here, but an area for optimization. This includes
    // assigning resolvedTableName
    final unresolvedTableOIDs = columns
        .where((f) => f != null)
        .map((f) => f!.tableID)
        .toSet()
        .where((oid) => oid > 0 && !_tableOIDNameMap.containsKey(oid))
        .toList()
      ..sort();

    if (unresolvedTableOIDs.isNotEmpty) {
      await _resolveTableOIDs(c, unresolvedTableOIDs);
    }

    return columns
        .map((c) => c!.change(tableName: _tableOIDNameMap[c.tableID]))
        .toList();
  }

  Future _resolveTableOIDs(
      _PostgreSQLExecutionContextMixin c, List<int> oids) async {
    _queryCount++;
    final unresolvedIDString = oids.join(',');
    final orderedTableNames = await c._query(
      "SELECT relname FROM pg_class WHERE relkind='r' AND oid IN ($unresolvedIDString) ORDER BY oid ASC",
      placeholderIdentifier: PlaceholderIdentifier.atSign,
      allowReuse: false, // inlined OIDs would make it difficult anyway
      resolveOids: false,
    );

    final iterator = oids.iterator;
    for (final tableName in orderedTableNames) {
      iterator.moveNext();
      if (tableName.first != null) {
        _tableOIDNameMap[iterator.current] = tableName.first as String;
      }
    }
  }
}

abstract class _PostgreSQLExecutionContextMixin
    implements PostgreSQLExecutionContext {
  final _queue = QueryQueue();

  PostgreSQLConnection get _connection;

  PostgreSQLExecutionContext get _transaction;

  @override
  int get queueSize => _queue.length;

  /// Break change
  @override
  Future<PostgreSQLResult> query(
    String fmtString, {
    dynamic substitutionValues,
    bool? allowReuse,
    int? timeoutInSeconds,
    bool? useSimpleQueryProtocol,
    PlaceholderIdentifier placeholderIdentifier = PlaceholderIdentifier.atSign,
  }) =>
      _query(fmtString,
          substitutionValues: substitutionValues,
          allowReuse: allowReuse ?? true,
          useSimpleQueryProtocol: useSimpleQueryProtocol ?? false,
          timeoutInSeconds: timeoutInSeconds,
          placeholderIdentifier: placeholderIdentifier);

  Future<PostgreSQLResult> _query(
    String fmtString, {
    dynamic substitutionValues,
    required bool allowReuse,
    required PlaceholderIdentifier placeholderIdentifier,
    int? timeoutInSeconds,
    bool resolveOids = true,
    bool useSimpleQueryProtocol = false,
  }) async {
    timeoutInSeconds ??= _connection.queryTimeoutInSeconds;

    if (useSimpleQueryProtocol) {
      // re-route the query to the `_execute` method which will execute the query
      // using the Simple Query Protocol.
      return _execute(fmtString,
          timeoutInSeconds: timeoutInSeconds,
          onlyReturnAffectedRows: false,
          substitutionValues: substitutionValues,
          placeholderIdentifier: placeholderIdentifier);
    }

    if (_connection.isClosed) {
      throw PostgreSQLException(
          'Attempting to execute query, but connection is not open.');
    }

    final query = Query<List<List<dynamic>>>(fmtString, substitutionValues,
        _connection, _transaction, StackTrace.current,
        placeholderIdentifier: placeholderIdentifier);
    if (allowReuse) {
      query.statementIdentifier = _connection._cache.identifierForQuery(query);
    }

    final queryResult =
        await _enqueue(query, timeoutInSeconds: timeoutInSeconds);
    var columnDescriptions = query.fieldDescriptions;
    if (resolveOids) {
      columnDescriptions = await _connection._oidCache
          ._resolveTableNames(this, columnDescriptions);
    }
    final metaData = _PostgreSQLResultMetaData(columnDescriptions!);

    return _PostgreSQLResult(
        queryResult.affectedRowCount,
        metaData,
        queryResult.value!
            .map((columns) => _PostgreSQLResultRow(metaData, columns))
            .toList());
  }

  @override
  Future<List<Map<String, Map<String, dynamic>>>> mappedResultsQuery(
    String fmtString, {
    dynamic substitutionValues = const <String, dynamic>{},
    bool? allowReuse,
    int? timeoutInSeconds,
    PlaceholderIdentifier placeholderIdentifier = PlaceholderIdentifier.atSign,
  }) async {
    final rs = await query(fmtString,
        substitutionValues: substitutionValues,
        allowReuse: allowReuse ?? false,
        timeoutInSeconds: timeoutInSeconds,
        placeholderIdentifier: placeholderIdentifier);

    return rs.map((row) => row.toTableColumnMap()).toList();
  }

  @override
  Future<int> execute(
    String fmtString, {
    dynamic substitutionValues = const <String, dynamic> {},
    int? timeoutInSeconds,
    PlaceholderIdentifier placeholderIdentifier = PlaceholderIdentifier.atSign,
  }) async {
    final result = await _execute(
      fmtString,
      substitutionValues: substitutionValues,
      timeoutInSeconds: _connection.queryTimeoutInSeconds,
      onlyReturnAffectedRows: true,
      placeholderIdentifier: placeholderIdentifier,
    );
    return result.affectedRowCount;
  }

  // TODO: replace [execute] with [_execute] and remove `useSimpleQueryProtocol`
  //       from the [query] method in the future major breaking change.
  Future<PostgreSQLResult> _execute(
    String fmtString, {
    dynamic substitutionValues = const <String, dynamic>{},
    required int timeoutInSeconds,
    required bool onlyReturnAffectedRows,
    required PlaceholderIdentifier placeholderIdentifier,
  }) async {
    if (_connection.isClosed) {
      throw PostgreSQLException(
          'Attempting to execute query, but connection is not open.');
    }

    final query = Query<dynamic>(
      fmtString, substitutionValues, _connection,
      _transaction, StackTrace.current,
      useSendSimple: true,
      // TODO: this could be removed from Query since useSendSimple covers the
      //       functionality.
      onlyReturnAffectedRowCount: onlyReturnAffectedRows,
      placeholderIdentifier: placeholderIdentifier,
    );

    final result = await _enqueue(query, timeoutInSeconds: timeoutInSeconds);

    final affectedRowCount = result.affectedRowCount;
    final columnDescriptions = query.fieldDescriptions ?? [];
    final metaData = _PostgreSQLResultMetaData(columnDescriptions);

    final value = result.value;
    late final List<PostgreSQLResultRow> rows;
    if (value != null && value is List<List>) {
      rows = value
          .map((columns) => _PostgreSQLResultRow(metaData, columns))
          .toList();
    } else {
      rows = [];
    }

    return _PostgreSQLResult(
      affectedRowCount,
      metaData,
      rows,
    );
  }

  @override
  void cancelTransaction({String? reason});

  Future<QueryResult<T>> _enqueue<T>(Query<T> query,
      {int timeoutInSeconds = 30}) async {
    if (_queue.add(query)) {
      _connection._transitionToState(_connection._connectionState.awake());

      try {
        final result =
            await query.future.timeout(Duration(seconds: timeoutInSeconds));
        _connection._cache.add(query);
        _queue.remove(query);
        return result!;
      } catch (e, st) {
        _queue.remove(query);
        await _onQueryError(query, e, st);
        rethrow;
      }
    } else {
      // wrap the synchronous future in an async future to ensure that
      // the caller behaves correctly in this condition. otherwise,
      // the caller would complete synchronously. This future
      // will always complete as a cancellation error.
      return Future(() async => (await query.future)!);
    }
  }

  Future _onQueryError(Query query, dynamic error, [StackTrace? trace]) async {}
}

class _PostgreSQLResultMetaData {
  final List<ColumnDescription> columnDescriptions;
  late List<String?> _tableNames;

  _PostgreSQLResultMetaData(this.columnDescriptions) {
    _tableNames =
        columnDescriptions.map((column) => column.tableName).toSet().toList();
  }

  List<String?> get tableNames {
    return _tableNames;
  }
}

class _PostgreSQLResult extends UnmodifiableListView<PostgreSQLResultRow>
    implements PostgreSQLResult {
  @override
  final int affectedRowCount;
  final _PostgreSQLResultMetaData _metaData;

  _PostgreSQLResult(
      this.affectedRowCount, this._metaData, List<PostgreSQLResultRow> rows)
      : super(rows);

  @override
  List<ColumnDescription> get columnDescriptions =>
      _metaData.columnDescriptions;
}

class _PostgreSQLResultRow extends UnmodifiableListView
    implements PostgreSQLResultRow {
  final _PostgreSQLResultMetaData _metaData;

  _PostgreSQLResultRow(this._metaData, List columns) : super(columns);

  @override
  List<ColumnDescription> get columnDescriptions =>
      _metaData.columnDescriptions;

  @override
  Map<String, Map<String, dynamic>> toTableColumnMap() {
    final rowMap = <String, Map<String, dynamic>>{};
    for (final tableName in _metaData.tableNames) {
      rowMap[tableName ?? ''] = <String, dynamic>{};
    }
    for (var i = 0; i < _metaData.columnDescriptions.length; i++) {
      final col = _metaData.columnDescriptions[i];
      rowMap[col.tableName]![col.columnName] = this[i];
    }
    return rowMap;
  }

  @override
  Map<String, dynamic> toColumnMap() {
    final rowMap = <String, dynamic>{};
    for (var i = 0; i < _metaData.columnDescriptions.length; i++) {
      final col = _metaData.columnDescriptions[i];
      rowMap[col.columnName] = this[i];
    }
    return rowMap;
  }
}
