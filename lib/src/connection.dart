part of postgres;

class PostgreSQLConnection {
  static const int ProtocolVersion = 196608;

  static const int BindIdentifier = 66;
  static const int DescribeIdentifier = 68;
  static const int ExecuteIdentifier = 69;
  static const int ParseIdentifier = 80;
  static const int QueryIdentifier = 81;
  static const int SyncIdentifier = 83;
  static const int PasswordIdentifier = 112;

  PostgreSQLConnection(this.host, this.port, this.databaseName, {this.username: null, this.password: null, this.timeoutInSeconds: 30, this.timeZone: "UTC", this.useSSL: false}) {
    _connectionState = new PostgreSQLConnectionStateClosed();
    _connectionState.connection = this;
  }

  // Values to be configured
  String host;
  int port;
  String databaseName;
  String username;
  String password;
  bool useSSL;

  int timeoutInSeconds;
  String timeZone;

  // Values for specific connection session
  Map<String, String> settings = null;
  Socket _socket;
  Completer _connectionFinishedOpening;
  _MessageFramer _framer;
  List<_SQLQuery> _queryQueue;
  _SQLQuery get _queryInTransit => _queryQueue.first;
  int _processID;
  int _secretKey;
  List<int> _salt;

  bool _hasConnectedPreviously = false;
  PostgreSQLConnectionState _connectionState;

  Future open() async {
    if (_hasConnectedPreviously) {
      throw new PostgreSQLConnectionException("Attempting to reopen a closed connection. Create a new instance instead.");
    }

    _hasConnectedPreviously = true;
    settings = {};
    _queryQueue = [];
    _connectionFinishedOpening = new Completer();

    if (useSSL) {
      _socket = await SecureSocket.connect(host, port).timeout(new Duration(seconds: timeoutInSeconds));
    } else {
      _socket = await Socket.connect(host, port).timeout(new Duration(seconds: timeoutInSeconds));
    }

    _framer = new _MessageFramer();
    _socket.listen(_readData, onError: _handleSocketError, onDone: _handleSocketClosed);

    _transitionToState(new PostgreSQLConnectionStateSocketConnected());

    return await _connectionFinishedOpening.future;
  }

  Future close() async {
    await _socket.close();
    _transitionToState(new PostgreSQLConnectionStateClosed());
  }


  Future<int> execute(String fmtString, {Map<String, dynamic> substitutionValues: null}) async {
    var readySQL = PostgreSQLFormatString.substitute(fmtString, substitutionValues);

    var query = new _SQLQuery(readySQL);
    _transitionToState(_connectionState.executeQuery(query));

    return query.future;
  }

  void _cleanup() {
    _processID = null;
    _secretKey = null;
    _salt = null;
    _queryQueue = null;
    _socket = null;
    _connectionFinishedOpening = null;
    _framer = null;
    settings = null;
  }

  void _transitionToState(PostgreSQLConnectionState newState) {
    _connectionState.onExit();

    _connectionState = newState;
    _connectionState.connection = this;

    _connectionState = _connectionState.onEnter();
    _connectionState.connection = this;
  }


  void _readData(List<int> bytes) {
    _framer.addBytes(bytes);

    try {
      while (_framer.hasMessage) {
        var msg = _framer.popMessage().message;

        print("$msg");
        var newState = null;
        if (msg is _ErrorResponseMessage) {
          newState = _connectionState.onErrorResponse(msg);
        } else {
          newState = _connectionState.onMessage(msg);
        }

        if (newState != _connectionState) {
          _transitionToState(newState);
        }
      }
    } on Exception catch (e) {
      _handleSocketError(e);
    }
  }

  void _handleSocketError(dynamic error) {
    _connectionFinishedOpening?.completeError(error);
    _socket.destroy();
    _transitionToState(new PostgreSQLConnectionStateClosed());
  }

  void _handleSocketClosed() {
    _transitionToState(new PostgreSQLConnectionStateClosed());
  }
}

class PostgreSQLConnectionException implements Exception {
  PostgreSQLConnectionException(this.message);
  final String message;

  String toString() => message;
}

int _applyStringToBuffer(String string, ByteData buffer, int offset) {
  var postStringOffset = string.codeUnits.fold(offset, (idx, unit) {
    buffer.setInt8(idx, unit);
    return idx + 1;
  });

  buffer.setInt8(postStringOffset, 0);
  return postStringOffset + 1;
}