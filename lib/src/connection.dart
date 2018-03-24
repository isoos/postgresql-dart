library postgres.connection;

import 'dart:async';
import 'dart:typed_data';

import 'message_window.dart';
import 'query.dart';

import 'server_messages.dart';
import 'dart:io';
import 'client_messages.dart';

part 'connection_fsm.dart';

part 'transaction_proxy.dart';

part 'exceptions.dart';

abstract class PostgreSQLExecutionContext {
  /// Executes a query on this context.
  ///
  /// This method sends the query described by [fmtString] to the database and returns a [Future] whose value is the returned rows from the query after the query completes.
  /// The format string may contain parameters that are provided in [substitutionValues]. Parameters are prefixed with the '@' character. Keys to replace the parameters
  /// do not include the '@' character. For example:
  ///
  ///         connection.query("SELECT * FROM table WHERE id = @idParam", {"idParam" : 2});
  ///
  /// The type of the value is inferred by default, but can be made more specific by adding ':type" to the parameter pattern in the format string. The possible values
  /// are declared as static variables in [PostgreSQLCodec] (e.g., [PostgreSQLCodec.TypeInt4]). For example:
  ///
  ///         connection.query("SELECT * FROM table WHERE id = @idParam:int4", {"idParam" : 2});
  ///
  /// You may also use [PostgreSQLFormat.id] to create parameter patterns.
  ///
  /// If successful, the returned [Future] completes with a [List] of rows. Each is row is represented by a [List] of column values for that row that were returned by the query.
  ///
  /// By default, instances of this class will reuse queries. This allows significantly more efficient transport to and from the database. You do not have to do
  /// anything to opt in to this behavior, this connection will track the necessary information required to reuse queries without intervention. (The [fmtString] is
  /// the unique identifier to look up reuse information.) You can disable reuse by passing false for [allowReuse].
  Future<List<List<dynamic>>> query(String fmtString,
      {Map<String, dynamic> substitutionValues: null, bool allowReuse: true});

  /// Executes a query on this context.
  ///
  /// This method sends a SQL string to the database this instance is connected to. Parameters can be provided in [fmtString], see [query] for more details.
  ///
  /// This method returns the number of rows affected and no additional information. This method uses the least efficient and less secure command
  /// for executing queries in the PostgreSQL protocol; [query] is preferred for queries that will be executed more than once, will contain user input,
  /// or return rows.
  Future<int> execute(String fmtString, {Map<String, dynamic> substitutionValues: null});

  /// Cancels a transaction on this context.
  ///
  /// If this context is an instance of [PostgreSQLConnection], this method has no effect. If the context is a transaction context (passed as the argument
  /// to [PostgreSQLConnection.transaction]), this will rollback the transaction.
  void cancelTransaction({String reason: null});
}

/// Instances of this class connect to and communicate with a PostgreSQL database.
///
/// The primary type of this library, a connection is responsible for connecting to databases and executing queries.
/// A connection may be opened with [open] after it is created.
class PostgreSQLConnection implements PostgreSQLExecutionContext {
  /// Creates an instance of [PostgreSQLConnection].
  ///
  /// [host] must be a hostname, e.g. "foobar.com" or IP address. Do not include scheme or port.
  /// [port] is the port to connect to the database on. It is typically 5432 for default PostgreSQL settings.
  /// [databaseName] is the name of the database to connect to.
  /// [username] and [password] are optional if the database requires user authentication.
  /// [timeoutInSeconds] refers to the amount of time [PostgreSQLConnection] will wait while establishing a connection before it gives up.
  /// [timeZone] is the timezone the connection is in. Defaults to 'UTC'.
  /// [useSSL] when true, uses a secure socket when connecting to a PostgreSQL database.
  PostgreSQLConnection(this.host, this.port, this.databaseName,
      {this.username: null, this.password: null, this.timeoutInSeconds: 30, this.timeZone: "UTC", this.useSSL: false}) {
    _connectionState = new _PostgreSQLConnectionStateClosed();
    _connectionState.connection = this;
  }

  final StreamController<Notification> _notifications = new StreamController<Notification>.broadcast();

  /// Hostname of database this connection refers to.
  String host;

  /// Port of database this connection refers to.
  int port;

  /// Name of database this connection refers to.
  String databaseName;

  /// Username for authenticating this connection.
  String username;

  /// Password for authenticating this connection.
  String password;

  /// Whether or not this connection should connect securely.
  bool useSSL;

  /// The amount of time this connection will wait during connecting before giving up.
  int timeoutInSeconds;

  /// The timezone of this connection for date operations that don't specify a timezone.
  String timeZone;

  /// The processID of this backend.
  int processID;

  /// Stream of notification from the database.
  ///
  /// Listen to this [Stream] to receive events from PostgreSQL NOTIFY commands.
  ///
  /// To determine whether or not the NOTIFY came from this instance, compare [processID]
  /// to [Notification.processID].
  Stream<Notification> get notifications => _notifications.stream;

  /// Whether or not this connection is open or not.
  ///
  /// This is [true] when this instance is first created and after it has been closed or encountered an unrecoverable error.
  /// If a connection has already been opened and this value is now true, the connection cannot be reopened and a new instance
  /// must be created.
  bool get isClosed => _connectionState is _PostgreSQLConnectionStateClosed;

  /// Settings values from the connected database.
  ///
  /// After connecting to a database, this map will contain the settings values that the database returns.
  /// Prior to connection, it is the empty map.
  Map<String, String> settings = {};

  Socket _socket;
  MessageFramer _framer = new MessageFramer();

  Map<String, QueryCache> _reuseMap = {};
  int _reuseCounter = 0;

  Map<int, String> _tableOIDNameMap = {};

  int _secretKey;
  List<int> _salt;

  bool _hasConnectedPreviously = false;
  _PostgreSQLConnectionState _connectionState;

  List<Query<dynamic>> _queryQueue = [];

  Query<dynamic> get _pendingQuery {
    if (_queryQueue.isEmpty) {
      return null;
    }
    return _queryQueue.first;
  }

  /// Establishes a connection with a PostgreSQL database.
  ///
  /// This method will return a [Future] that completes when the connection is established. Queries can be executed
  /// on this connection afterwards. If the connection fails to be established for any reason - including authentication -
  /// the returned [Future] will return with an error.
  ///
  /// Connections may not be reopened after they are closed or opened more than once. If a connection has already been opened and this method is called, an exception will be thrown.
  Future open() async {
    if (_hasConnectedPreviously) {
      throw new PostgreSQLException("Attempting to reopen a closed connection. Create a new instance instead.");
    }

    _hasConnectedPreviously = true;
    _socket = await Socket.connect(host, port).timeout(new Duration(seconds: timeoutInSeconds), onTimeout: _timeout);

    _framer = new MessageFramer();
    if (useSSL) {
      _socket = await _upgradeSocketToSSL(_socket, timeout: timeoutInSeconds);
    }

    var connectionComplete = new Completer();

    _socket.listen(_readData, onError: _handleSocketError, onDone: _handleSocketClosed);

    _transitionToState(new _PostgreSQLConnectionStateSocketConnected(connectionComplete));

    return connectionComplete.future.timeout(new Duration(seconds: timeoutInSeconds), onTimeout: _timeout);
  }

  /// Closes a connection.
  ///
  /// After the returned [Future] completes, this connection can no longer be used to execute queries. Any queries in progress or queued are cancelled.
  Future close() async {
    _connectionState = new _PostgreSQLConnectionStateClosed();

    await _socket?.close();

    _cancelCurrentQueries();

    return _cleanup();
  }

  /// Executes a query on this connection.
  ///
  /// This method sends the query described by [fmtString] to the database and returns a [Future] whose value returned rows from the query after the query completes.
  /// The format string may contain parameters that are provided in [substitutionValues]. Parameters are prefixed with the '@' character. Keys to replace the parameters
  /// do not include the '@' character. For example:
  ///
  ///         connection.query("SELECT * FROM table WHERE id = @idParam", {"idParam" : 2});
  ///
  /// The type of the value is inferred by default, but can be made more specific by adding ':type" to the parameter pattern in the format string. The possible values
  /// are declared as static variables in [PostgreSQLCodec] (e.g., [PostgreSQLCodec.TypeInt4]). For example:
  ///
  ///         connection.query("SELECT * FROM table WHERE id = @idParam:int4", {"idParam" : 2});
  ///
  /// You may also use [PostgreSQLFormat.id] to create parameter patterns.
  ///
  /// If successful, the returned [Future] completes with a [List] of rows. Each is row is represented by a [List] of column values for that row that were returned by the query.
  ///
  /// By default, instances of this class will reuse queries. This allows significantly more efficient transport to and from the database. You do not have to do
  /// anything to opt in to this behavior, this connection will track the necessary information required to reuse queries without intervention. (The [fmtString] is
  /// the unique identifier to look up reuse information.) You can disable reuse by passing false for [allowReuse].
  ///
  Future<List<List<dynamic>>> query(String fmtString,
      {Map<String, dynamic> substitutionValues: null, bool allowReuse: true}) async {
    if (isClosed) {
      throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
    }

    var query = new Query<List<List<dynamic>>>(fmtString, substitutionValues, this, null);
    if (allowReuse) {
      query.statementIdentifier = _reuseIdentifierForQuery(query);
    }

    final rows = await _enqueue(query);
    return rows.map((Iterable<dynamic> row) => row.toList()).toList();
  }

  /// Executes a query on this connection and returns each row as a [Map].
  ///
  /// This method constructs and executes a query in the same way as [query], but returns each row as a [Map].
  ///
  /// (Note: this method will execute additional queries to resolve table names the first time a table is encountered. These table names are cached per instance of this type.)
  ///
  /// Each row map contains key-value pairs for every table in the query. The value is a [Map] that contains
  /// key-value pairs for each column from that table. For example, consider
  /// the following query:
  ///
  ///         SELECT employee.id, employee.name FROM employee;
  ///
  /// This method would return the following structure:
  ///
  ///         [
  ///           {"employee" : {"name": "Bob", "id": 1}}
  ///         ]
  ///
  /// The purpose of this nested structure is to disambiguate columns that have the same name in different tables. For example, consider a query with a SQL JOIN:
  ///
  ///         SELECT employee.id, employee.name, company.name FROM employee LEFT OUTER JOIN company ON employee.company_id=company.id;
  ///
  /// Each returned [Map] would contain `employee` and `company` keys. The `name` key would be present in both inner maps.
  ///
  ///       [
  ///         {
  ///           "employee": {"name": "Bob", "id": 1},
  ///           "company: {"name": "stable|kernel"}
  ///         }
  ///       ]
  Future<List<Map<String, Map<String, dynamic>>>> mappedResultsQuery(String fmtString,
      {Map<String, dynamic> substitutionValues: null, bool allowReuse: true}) async {
    if (isClosed) {
      throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
    }

    var query = new Query<List<List<dynamic>>>(fmtString, substitutionValues, this, null);
    if (allowReuse) {
      query.statementIdentifier = _reuseIdentifierForQuery(query);
    }

    final rows = await _enqueue(query);

    return _mapifyRows(rows, query.fieldDescriptions);
  }

  /// Executes a query on this connection.
  ///
  /// This method sends a SQL string to the database this instance is connected to. Parameters can be provided in [fmtString], see [query] for more details.
  ///
  /// This method returns the number of rows affected and no additional information. This method uses the least efficient and less secure command
  /// for executing queries in the PostgreSQL protocol; [query] is preferred for queries that will be executed more than once, will contain user input,
  /// or return rows.
  Future<int> execute(String fmtString, {Map<String, dynamic> substitutionValues: null}) {
    if (isClosed) {
      throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
    }

    var query = new Query<int>(fmtString, substitutionValues, this, null)
      ..onlyReturnAffectedRowCount = true;

    return _enqueue(query);
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
  /// Do not catch exceptions within a transaction block, as it will prevent the transaction exception handler from fulfilling a
  /// transaction.
  ///
  /// Transactions may be cancelled by issuing [PostgreSQLExecutionContext.cancelTransaction]
  /// within the transaction. This will cause this method to return a [Future] with a value of [PostgreSQLRollback]. This method does not throw an exception
  /// if the transaction is cancelled in this way.
  ///
  /// All queries within a transaction block must be executed using the [PostgreSQLExecutionContext] passed into the [queryBlock].
  /// You must not issue queries to the receiver of this method from within the [queryBlock], otherwise the connection will deadlock.
  ///
  /// Queries within a transaction may be executed asynchronously or be awaited on. The order is still guaranteed. Example:
  ///
  ///         connection.transaction((ctx) {
  ///           var rows = await ctx.query("SELECT id FROM t);
  ///           if (!rows.contains([2])) {
  ///             ctx.query("INSERT INTO t (id) VALUES (2)");
  ///           }
  ///         });
  Future<dynamic> transaction(Future<dynamic> queryBlock(PostgreSQLExecutionContext connection)) async {
    if (isClosed) {
      throw new PostgreSQLException("Attempting to execute query, but connection is not open.");
    }

    var proxy = new _TransactionProxy(this, queryBlock);

    await _enqueue(proxy.beginQuery);

    return await proxy.completer.future;
  }

  void cancelTransaction({String reason: null}) {
    // We aren't in a transaction if sent to PostgreSQLConnection instances, so this is a no-op.
  }

  ////////

  Future<List<Map<String, Map<String, dynamic>>>> _mapifyRows(
      List<List<dynamic>> rows, List<FieldDescription> columns) async {
    //todo (joeconwaystk): If this was a cached query, resolving is table oids is unnecessary.
    // It's not a significant impact here, but an area for optimization. This includes
    // assigning resolvedTableName
    final tableOIDs = new Set.from(columns.map((f) => f.tableID));
    final unresolvedTableOIDs = tableOIDs.where((oid) => oid != null && !_tableOIDNameMap.containsKey(oid)).toList()
      ..sort((int lhs, int rhs) => lhs.compareTo(rhs));

    if (unresolvedTableOIDs.isNotEmpty) {
      await _resolveTableOIDs(unresolvedTableOIDs);
    }

    columns.forEach((desc) {
      desc.resolvedTableName = _tableOIDNameMap[desc.tableID];
    });

    final tableNames = tableOIDs.map((oid) => _tableOIDNameMap[oid]).toList();
    return rows.map((row) {
      var rowMap = new Map.fromIterable(tableNames, key: (name) => name, value: (_) => {});

      final iterator = columns.iterator;
      row.forEach((column) {
        iterator.moveNext();
        rowMap[iterator.current.resolvedTableName][iterator.current.fieldName] = column;
      });

      return rowMap;
    }).toList();
  }

  Future _resolveTableOIDs(List<int> oids) async {
    final unresolvedIDString = oids.join(",");
    final orderedTableNames = await query(
      "SELECT relname FROM pg_class WHERE relkind='r' AND oid IN ($unresolvedIDString) ORDER BY oid ASC");

    final iterator = oids.iterator;
    orderedTableNames.forEach((tableName) {
      iterator.moveNext();
      if (tableName.first != null) {
        _tableOIDNameMap[iterator.current] = tableName.first;
      }
    });
  }

  void _timeout() {
    _connectionState = new _PostgreSQLConnectionStateClosed();
    _socket?.destroy();

    _cancelCurrentQueries();
    _cleanup();
    throw new PostgreSQLException("Timed out trying to connect to database postgres://$host:$port/$databaseName.");
  }

  Future<T> _enqueue<T>(Query<T> query) async {
    _queryQueue.add(query);
    _transitionToState(_connectionState.awake());

    var result = null;
    try {
      result = await query.future;
      _cacheQuery(query);
      _queryQueue.remove(query);
    } catch (e) {
      _cacheQuery(query);
      _queryQueue.remove(query);
      rethrow;
    }

    return result;
  }

  void _cancelCurrentQueries([Object error, StackTrace stackTrace]) {
    error ??= "Cancelled";
    var queries = _queryQueue;
    _queryQueue = [];

    // We need to jump this to the next event so that the queries
    // get the error and not the close message, since completeError is
    // synchronous.
    scheduleMicrotask(() {
      var exception =
          new PostgreSQLException("Connection closed or query cancelled (reason: $error).", stackTrace: stackTrace);
      queries?.forEach((q) {
        q.completeError(exception, stackTrace);
      });
    });
  }

  void _transitionToState(_PostgreSQLConnectionState newState) {
    if (identical(newState, _connectionState)) {
      return;
    }

    _connectionState.onExit();

    _connectionState = newState;
    _connectionState.connection = this;

    _connectionState = _connectionState.onEnter();
    _connectionState.connection = this;
  }

  void _readData(List<int> bytes) {
    // Note that the way this method works, if a query is in-flight, and we move to the closed state
    // manually, the delivery of the bytes from the socket is sent to the 'Closed State',
    // and the state node managing delivering data to the query no longer exists. Therefore,
    // as soon as a close occurs, we detach the data stream from anything that actually does
    // anything with that data.
    _framer.addBytes(bytes);
    while (_framer.hasMessage) {
      var msg = _framer.popMessage().message;
      try {
        if (msg is ErrorResponseMessage) {
          _transitionToState(_connectionState.onErrorResponse(msg));
        } else if (msg is NotificationResponseMessage) {
          _notifications.add(new Notification(msg.processID, msg.channel, msg.payload));
        } else {
          _transitionToState(_connectionState.onMessage(msg));
        }
      } catch (e, st) {
        _handleSocketError(e, st);
      }
    }
  }

  void _handleSocketError(Object error, StackTrace stack) {
    _connectionState = new _PostgreSQLConnectionStateClosed();
    _socket.destroy();

    _cancelCurrentQueries(error, stack);
    _cleanup();
  }

  void _handleSocketClosed() {
    _connectionState = new _PostgreSQLConnectionStateClosed();

    _cancelCurrentQueries();
    _cleanup();
  }

  Future<Socket> _upgradeSocketToSSL(Socket originalSocket, {int timeout: 30}) async {
    var sslCompleter = new Completer<int>();

    originalSocket.listen(
        (data) {
          if (data.length != 1) {
            sslCompleter.completeError(
                new PostgreSQLException("Could not initalize SSL connection, received unknown byte stream."));
            return;
          }

          sslCompleter.complete(data.first);
        },
        onDone: () => sslCompleter.completeError(
            new PostgreSQLException("Could not initialize SSL connection, connection closed during handshake.")),
        onError: (err) {
          sslCompleter.completeError(err);
        });

    var byteBuffer = new ByteData(8);
    byteBuffer.setUint32(0, 8);
    byteBuffer.setUint32(4, 80877103);
    originalSocket.add(byteBuffer.buffer.asUint8List());

    var responseByte = await sslCompleter.future.timeout(new Duration(seconds: timeout), onTimeout: _timeout);
    if (responseByte == 83) {
      return SecureSocket
          .secure(originalSocket, onBadCertificate: (certificate) => true)
          .timeout(new Duration(seconds: timeout), onTimeout: _timeout);
    }

    throw new PostgreSQLException("SSL not allowed for this connection.");
  }

  void _cacheQuery(Query<dynamic> query) {
    if (query.cache == null) {
      return;
    }

    if (query.cache.isValid) {
      _reuseMap[query.statement] = query.cache;
    }
  }

  QueryCache _cachedQuery(String statementIdentifier) {
    if (statementIdentifier == null) {
      return null;
    }

    return _reuseMap[statementIdentifier];
  }

  String _reuseIdentifierForQuery(Query<dynamic> q) {
    var existing = _reuseMap[q.statement];
    if (existing != null) {
      return existing.preparedStatementName;
    }

    var string = "$_reuseCounter".padLeft(12, "0");

    _reuseCounter++;

    return string;
  }

  Future _cleanup() async {
    await _notifications.close();
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
