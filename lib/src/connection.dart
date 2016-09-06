part of postgres;

class PostgreSQLConnection {
  PostgreSQLConnection(this.host, this.port, this.databaseName, {this.username: null, this.password: null, this.timeoutInSeconds: 30, this.timeZone: "UTC", this.useSSL: false}) {
    _connectionState = new PostgreSQLConnectionStateClosed();
    _connectionState.connection = this;
  }

  // Add flag for debugging that captures stack trace prior to execution

  // Values to be configured
  String host;
  int port;
  String databaseName;
  String username;
  String password;
  bool useSSL;
  int timeoutInSeconds;
  String timeZone;

  Map<String, String> settings = {};

  Socket _socket;
  _MessageFramer _framer = new _MessageFramer();
  List<_SQLQuery> _queryQueue = [];

  int _processID;
  int _secretKey;
  List<int> _salt;

  bool _hasConnectedPreviously = false;
  PostgreSQLConnectionState _connectionState;

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

    _transitionToState(new PostgreSQLConnectionStateSocketConnected());

    return await _connectionState.pendingOperation.future.timeout(new Duration(seconds: timeoutInSeconds), onTimeout: () {
      _connectionState = new PostgreSQLConnectionStateClosed();
      _socket.destroy();

      throw new PostgreSQLException("Timed out trying to connect to database $host:$port/$databaseName.");
    });
  }

  Future close() async {
    _connectionState = new PostgreSQLConnectionStateClosed();

    await _socket.close();

    cancelCurrentQueries();
  }

  Future<List<List<dynamic>>> query(String fmtString, {Map<String, dynamic> substitutionValues: null}) async {
    var query = new _SQLQuery(fmtString, substitutionValues);

    _transitionToState(_connectionState.queueQuery(query));

    return query.future;
  }

  Future<int> execute(String fmtString, {Map<String, dynamic> substitutionValues: null}) async {
    var query = new _SQLQuery(fmtString, substitutionValues);
    query.onlyReturnAffectedRowCount = true;

    _transitionToState(_connectionState.queueQuery(query));

    return query.future;
  }

  void _transitionToState(PostgreSQLConnectionState newState) {
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
    _connectionState = new PostgreSQLConnectionStateClosed();
    _socket.destroy();

    cancelCurrentQueries();
  }

  void _handleSocketClosed() {
    _connectionState = new PostgreSQLConnectionStateClosed();

    cancelCurrentQueries();
  }

  void cancelCurrentQueries() {
    _queryQueue?.forEach((q) {
      q.onComplete.completeError(new PostgreSQLException("Connection closed."));
    });
    _queryQueue = null;
  }
}