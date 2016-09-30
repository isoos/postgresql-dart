part of postgres;

/// Instances of this class connect to and communicate with a PostgreSQL database.
///
/// The primary type of this library, a connection is responsible for connecting to databases and executing queries.
/// A connection may be opened with [open] after it is created.
class PostgreSQLConnection {

  /// Creates an instance of [PostgreSQLConnection].
  ///
  /// [host] must be a hostname, e.g. "foobar.com" or IP address. Do not include scheme or port.
  /// [port] is the port to connect to the database on. It is typically 5432 for default PostgreSQL settings.
  /// [databaseName] is the name of the database to connect to.
  /// [username] and [password] are optional if the database requires user authentication.
  /// [timeoutInSeconds] refers to the amount of time [PostgreSQLConnection] will wait while establishing a connection before it gives up.
  /// [timeZone] is the timezone the connection is in. Defaults to 'UTC'.
  /// [useSSL] when true, uses a secure socket when connecting to a PostgreSQL database.
  PostgreSQLConnection(this.host, this.port, this.databaseName, {this.username: null, this.password: null, this.timeoutInSeconds: 30, this.timeZone: "UTC", this.useSSL: false}) {
    _connectionState = new _PostgreSQLConnectionStateClosed();
    _connectionState.connection = this;
  }

  // Add flag for debugging that captures stack trace prior to execution

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
  _MessageFramer _framer = new _MessageFramer();
  List<_Query> _queryQueue = [];
  Map<String, _QueryCache> _reuseMap = {};
  int _reuseCounter = 0;

  int _processID;
  int _secretKey;
  List<int> _salt;

  bool _hasConnectedPreviously = false;
  _PostgreSQLConnectionState _connectionState;

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

    if (useSSL) {
      _socket = await SecureSocket.connect(host, port).timeout(new Duration(seconds: timeoutInSeconds));
    } else {
      _socket = await Socket.connect(host, port).timeout(new Duration(seconds: timeoutInSeconds));
    }

    _framer = new _MessageFramer();
    _socket.listen(_readData, onError: _handleSocketError, onDone: _handleSocketClosed);

    _transitionToState(new _PostgreSQLConnectionStateSocketConnected());

    return await _connectionState.pendingOperation.future.timeout(new Duration(seconds: timeoutInSeconds), onTimeout: () {
      _connectionState = new _PostgreSQLConnectionStateClosed();
      _socket.destroy();

      throw new PostgreSQLException("Timed out trying to connect to database $host:$port/$databaseName.");
    });
  }

  /// Closes a connection.
  ///
  /// After the returned [Future] completes, this connection can no longer be used to execute queries. Any queries in progress or queued are cancelled.
  Future close() async {
    _connectionState = new _PostgreSQLConnectionStateClosed();

    await _socket?.close();

    _cancelCurrentQueries();
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
  Future<List<List<dynamic>>> query(String fmtString, {Map<String, dynamic> substitutionValues: null, bool allowReuse: true}) async {
    var query = new _Query<List<List<dynamic>>>(fmtString, substitutionValues)
      ..allowReuse = allowReuse;

    _transitionToState(_connectionState.queueQuery(query));

    return query.future;
  }

  /// Executes a query on this connection.
  ///
  /// This method sends a SQL string to the database this instance is connected to. Parameters can be provided in [fmtString], see [query] for more details.
  ///
  /// This method returns the number of rows affected and no additional information. This method uses the least efficient and less secure command
  /// for executing queries in the PostgreSQL protocol; [query] is preferred for queries that will be executed more than once, will contain user input,
  /// or return rows.
  Future<int> execute(String fmtString, {Map<String, dynamic> substitutionValues: null}) async {
    var query = new _Query<int>(fmtString, substitutionValues);
    query.onlyReturnAffectedRowCount = true;

    _transitionToState(_connectionState.queueQuery(query));

    return query.future;
  }

  void _cancelCurrentQueries() {
    _queryQueue?.forEach((q) {
      q.completeError(new PostgreSQLException("Connection closed or query cancelled."));
    });
    _queryQueue = null;
  }


  void _transitionToState(_PostgreSQLConnectionState newState) {
    if (newState == _connectionState) {
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
        if (msg is _ErrorResponseMessage) {
          _transitionToState(_connectionState.onErrorResponse(msg));
        } else {
          _transitionToState(_connectionState.onMessage(msg));
        }
      } on Exception catch (e) {
        _handleSocketError(e);
      }
    }
  }

  void _handleSocketError(dynamic error) {
    _connectionState = new _PostgreSQLConnectionStateClosed();
    _socket.destroy();

    _cancelCurrentQueries();
  }

  void _handleSocketClosed() {
    _connectionState = new _PostgreSQLConnectionStateClosed();

    _cancelCurrentQueries();
  }

  void _cacheQuery(_Query query, _QueryCache cache) {
    _reuseMap[query.statement] = cache;
  }

  String _generateNextQueryIdentifier() {
    var string = "$_reuseCounter".padLeft(12, "0");

    _reuseCounter ++;

    return string;
  }
}