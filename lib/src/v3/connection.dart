import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart' as async;
import 'package:charcode/ascii.dart';
import 'package:meta/meta.dart';
import 'package:pool/pool.dart' as pool;
import 'package:postgres/src/types/type_registry.dart';
import 'package:stream_channel/stream_channel.dart';

import '../../postgres.dart';
import '../auth/auth.dart';
import 'protocol.dart';
import 'query_description.dart';
import 'resolved_settings.dart';

const _debugLog = false;

String _identifier(String source) {
  // To avoid complex ambiguity rules, we always wrap identifier in double
  // quotes. That means the only character we need to escape are double quotes
  // in the source.
  final escaped = source.replaceAll('"', '""');
  return '"$escaped"';
}

abstract class _PgSessionBase implements Session {
  /// The lock to guard operations that must run sequentially, like sending
  /// RPC messages to the postgres server and waiting for them to complete.
  ///
  /// Each session base has its own operation lock, but child sessions hold the
  /// parent lock while they are active. For instance, when starting a
  /// transaction,the [_operationLock] of the connection is held until the
  /// transaction completes. This ensures that no other statement can use the
  /// connection in the meantime.
  final _operationLock = pool.Pool(1);

  final Completer<void> _sessionClosedCompleter = Completer();

  bool get _sessionClosed => _sessionClosedCompleter.isCompleted;

  PgConnectionImplementation get _connection;
  ResolvedSessionSettings get _settings;
  Encoding get encoding => _connection._settings.encoding;

  void _closeSession() {
    if (!_sessionClosed) {
      _sessionClosedCompleter.complete();
    }
  }

  void _checkActive() {
    if (_sessionClosed) {
      throw PgException(
          'Session or transaction has already finished, did you forget to await a statement?');
    } else if (_connection._isClosing) {
      throw PgException('Connection is closing down');
    }
  }

  /// Runs [callback], guarded by [_operationLock] and cleans up the pending
  /// resource afterwards.
  Future<T> _withResource<T>(FutureOr<T> Function() callback) {
    _checkActive();
    return _operationLock.withResource(() {
      _checkActive();
      assert(_connection._pending == null,
          'Previous operation ${_connection._pending} did not clean up.');

      return Future(callback).whenComplete(() {
        _connection._pending = null;
      });
    });
  }

  /// Sends a message to the server and waits for a response [T], gracefully
  /// handling error messages that might come in instead.
  Future<T> _sendAndWaitForQuery<T extends ServerMessage>(ClientMessage send) {
    final trace = StackTrace.current;

    return _withResource(() {
      _connection._channel.sink
          .add(AggregatedClientMessage([send, const SyncMessage()]));

      final wait = _connection._pending = _WaitForMessage<T>(this, trace);

      return wait.doneWithOperation.future.then((value) {
        final effectiveResult = wait.result ??
            async.Result.error(StateError('Operation did not complete'), trace);

        return effectiveResult.asFuture;
      });
    });
  }

  @override
  bool get isOpen => !_sessionClosed && !_connection._isClosing;

  @override
  Future<void> get closed => _sessionClosedCompleter.future;

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async {
    if (_connection._isClosing || _sessionClosed) {
      throw PgException(
          'Attempting to execute query, but connection is not open.');
    }
    final description = InternalQueryDescription.wrap(
      query,
      typeRegistry: _connection._settings.typeRegistry,
    );
    final variables = description.bindParameters(
      parameters,
      ignoreSuperfluous: _settings.ignoreSuperfluousParameters,
    );

    queryMode ??= _settings.queryMode;
    final isSimple = queryMode == QueryMode.simple;

    if (isSimple && variables.isNotEmpty) {
      throw PgException('Parameterized queries are not supported when '
          'using the Simple Query Protocol');
    }

    if (isSimple || (ignoreRows && variables.isEmpty)) {
      _connection._queryCount++;
      // Great, we can just run a simple query.
      final controller = StreamController<ResultRow>();
      final items = <ResultRow>[];

      final querySubscription = _PgResultStreamSubscription.simpleQueryProtocol(
        description.transformedSql,
        this,
        controller,
        controller.stream.listen(items.add),
        ignoreRows,
      );
      try {
        await querySubscription.asFuture().optionalTimeout(timeout);
        return Result(
          rows: items,
          affectedRows: await querySubscription.affectedRows,
          schema: await querySubscription.schema,
        );
      } finally {
        await querySubscription.cancel();
      }
    } else {
      // The simple query protocol does not support variables. So when we have
      // parameters, we need an explicit prepare.
      final prepared = await _prepare(description, timeout: timeout);
      try {
        return await prepared.run(variables, timeout: timeout);
      } finally {
        await prepared.dispose();
      }
    }
  }

  @override
  Future<Statement> prepare(Object query) async => await _prepare(query);

  Future<_PreparedStatement> _prepare(
    Object query, {
    Duration? timeout,
  }) async {
    final conn = _connection;
    final name = 's/${conn._statementCounter++}';
    final description = InternalQueryDescription.wrap(
      query,
      typeRegistry: _connection._settings.typeRegistry,
    );

    await _sendAndWaitForQuery<ParseCompleteMessage>(ParseMessage(
      description.transformedSql,
      statementName: name,
      typeOids: description.parameterTypes?.map((e) => e?.oid).toList(),
    )).optionalTimeout(timeout);

    return _PreparedStatement(description, name, this);
  }
}

class PgConnectionImplementation extends _PgSessionBase implements Connection {
  static Future<PgConnectionImplementation> connect(
    Endpoint endpoint, {
    ConnectionSettings? connectionSettings,
  }) async {
    final settings = connectionSettings is ResolvedConnectionSettings
        ? connectionSettings
        : ResolvedConnectionSettings(connectionSettings, null);
    var (channel, secure) = await _connect(endpoint, settings);

    if (_debugLog) {
      channel = channel.transform(StreamChannelTransformer(
        StreamTransformer.fromHandlers(
          handleData: (msg, sink) {
            print('[in] $msg');
            sink.add(msg);
          },
        ),
        async.StreamSinkTransformer.fromHandlers(handleData: (msg, sink) {
          print('[out] $msg');
          sink.add(msg);
        }),
      ));
    }

    if (settings.transformer != null) {
      channel = channel.transform(settings.transformer!);
    }

    final connection =
        PgConnectionImplementation._(endpoint, settings, channel, secure);
    await connection._startup();
    if (connection._settings.onOpen != null) {
      await connection._settings.onOpen!(connection);
    }
    return connection;
  }

  static Future<(StreamChannel<Message>, bool)> _connect(
    Endpoint endpoint,
    ResolvedConnectionSettings settings,
  ) async {
    final host = endpoint.host;
    final port = endpoint.port;

    var socket = await Socket.connect(
      endpoint.isUnixSocket
          ? InternetAddress(host, type: InternetAddressType.unix)
          : host,
      port,
      timeout: settings.connectTimeout,
    );

    final sslCompleter = Completer<int>();
    // ignore: cancel_subscriptions
    final subscription = socket.listen(
      (data) {
        if (sslCompleter.isCompleted) {
          return;
        }
        if (data.length != 1) {
          sslCompleter.completeError(PgException(
              'Could not initialize SSL connection, received unknown byte stream.'));
          return;
        }

        sslCompleter.complete(data.first);
      },
      onDone: () {
        if (sslCompleter.isCompleted) {
          return;
        }
        sslCompleter.completeError(PgException(
            'Could not initialize SSL connection, connection closed during handshake.'));
      },
      onError: (e) {
        if (sslCompleter.isCompleted) {
          return;
        }
        sslCompleter.completeError(e);
      },
    );

    Stream<Uint8List> adaptedStream;
    var secure = false;

    if (settings.sslMode != SslMode.disable) {
      // Query if SSL is possible by sending a SSLRequest message
      final byteBuffer = ByteData(8);
      byteBuffer.setUint32(0, 8);
      byteBuffer.setUint32(4, 80877103);
      socket.add(byteBuffer.buffer.asUint8List());

      final byte = await sslCompleter.future.timeout(settings.connectTimeout);

      if (byte == $S) {
        // SSL is supported, upgrade!
        subscription.pause();

        socket = await SecureSocket.secure(
          socket,
          context: settings.securityContext,
          onBadCertificate: settings.sslMode.ignoreCertificateIssues
              ? (_) => true
              : (c) => throw BadCertificateException(c),
        ).timeout(settings.connectTimeout);
        secure = true;

        // We can listen to the secured socket again, the existing subscription is
        // ignored.
        adaptedStream = socket;
      } else {
        // This server does not support SSL
        throw PgException('Server does not support SSL, but it was required.');
      }
    } else {
      // We've listened to the stream already and sockets are single-subscription
      // streams. Expose it as a new stream.
      adaptedStream = async.SubscriptionStream(subscription);
    }

    final outgoingSocket = async.StreamSinkExtensions(socket)
        .transform<Uint8List>(
            async.StreamSinkTransformer.fromHandlers(handleDone: (out) {
      // As per the stream channel's guarantees, closing the sink should close
      // the channel in both directions.
      socket.destroy();
      return out.close();
    }));

    return (
      StreamChannel<List<int>>(adaptedStream, outgoingSocket)
          .transform(messageTransformer(settings.encoding)),
      secure,
    );
  }

  final Endpoint _endpoint;
  @override
  final ResolvedConnectionSettings _settings;
  final StreamChannel<Message> _channel;

  /// Whether [_channel] is backed by a TLS connection.
  final bool _channelIsSecure;
  late final StreamSubscription<Message> _serverMessages;
  bool _isClosing = false;

  _PendingOperation? _pending;
  // Errors happening while a transaction is active will roll back the
  // transaction and should be reporte to the user.
  _TransactionSession? _activeTransaction;

  final _parameters = <String, String>{};

  var _statementCounter = 0;
  var _portalCounter = 0;
  var _queryCount = 0;

  late final _channels = _Channels(this);

  @internal
  int get queryCount => _queryCount;

  @override
  Channels get channels => _channels;

  @override
  PgConnectionImplementation get _connection => this;

  PgConnectionImplementation._(
      this._endpoint, this._settings, this._channel, this._channelIsSecure) {
    _serverMessages = _channel.stream
        .listen(_handleMessage, onDone: _socketClosed, onError: (e, s) {
      _close(
        true,
        PgException('Socket error: $e'),
        socketIsBroken: true,
      );
    });
  }

  Future<void> _startup() {
    return _withResource(() {
      final result =
          _pending = _AuthenticationProcedure(this, _channelIsSecure);

      _channel.sink.add(StartupMessage(
        database: _endpoint.database,
        timeZone: _settings.timeZone,
        username: _endpoint.username,
        replication: _settings.replicationMode,
        applicationName: _settings.applicationName,
      ));

      return result._done.future.timeout(_settings.connectTimeout);
    });
  }

  Future<void> _socketClosed() async {
    await _close(
      true,
      PgException(
          'The underlying socket to Postgres has been closed unexpectedly.'),
      socketIsBroken: true,
    );
  }

  Future<void> _handleMessage(Message message) async {
    _serverMessages.pause();
    try {
      message as ServerMessage;

      if (message is ParameterStatusMessage) {
        _parameters[message.name] = message.value;
      } else if (message is BackendKeyMessage || message is NoticeMessage) {
        // ignore for now
      } else if (message is NotificationResponseMessage) {
        _channels.deliverNotification(message);
      } else if (message is ErrorResponseMessage) {
        final exception = ServerException.fromFields(message.fields);

        // Close the connection in response to fatal errors or if we get them
        // out of nowhere.
        if (exception.willAbortConnection || _pending == null) {
          _closeAfterError(exception);
        } else {
          _connection._activeTransaction?._transactionException = exception;

          _pending!.handleError(exception);
        }
      } else if (_pending != null) {
        await _pending!.handleMessage(message);
      }
    } finally {
      _serverMessages.resume();
    }
  }

  @override
  Future<void> get closed => _channel.sink.done;

  @override
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    SessionSettings? settings,
  }) {
    final session =
        _RegularSession(this, ResolvedSessionSettings(settings, _settings));
    // Unlike runTx, this doesn't need any locks. An active transaction changes
    // the state of the connection, this method does not. If methods requiring
    // locks are called by [fn], these methods will aquire locks as needed.
    return Future<R>(() => fn(session)).whenComplete(session._closeSession);
  }

  @override
  Future<R> runTx<R>(
    Future<R> Function(TxSession session) fn, {
    TransactionSettings? settings,
  }) {
    final rsettings = ResolvedTransactionSettings(settings, _settings);
    // Keep this database is locked while the transaction is active. We do that
    // because on a protocol level, the entire connection is in a transaction.
    // From a Dart point of view, methods called outside of the transaction
    // should not be able to view data in the transaction though. So we avoid
    // those outer calls while the transaction is active and resume them by
    // returning the operation lock in the end.
    return _operationLock.withResource(() async {
      // The transaction has its own _operationLock, which means that it (and
      // only it) can be used to run statements while it's active.
      final transaction =
          _connection._activeTransaction = _TransactionSession(this, rsettings);

      late String beginQuery;
      if (rsettings.shouldExpandBegin) {
        final sb = StringBuffer('BEGIN');
        rsettings.expandBegin(sb);
        sb.write(';');
        beginQuery = sb.toString();
      } else {
        beginQuery = 'BEGIN;';
      }

      await transaction.execute(
        Sql(beginQuery),
        queryMode: QueryMode.simple,
      );

      try {
        final result = await fn(transaction);
        if (transaction.mayCommit) {
          await transaction._sendAndMarkClosed('COMMIT;');
        } else if (!transaction._sessionClosed) {
          await transaction._sendAndMarkClosed('ROLLBACK;');
        }

        // If we have received an error while the transaction was active, it
        // will always be rolled back.
        if (transaction._transactionException case final PgException e) {
          throw e;
        }

        return result;
      } catch (e) {
        if (!transaction._sessionClosed) {
          await transaction._sendAndMarkClosed('ROLLBACK;');
        }

        rethrow;
      }
    });
  }

  @override
  Future<void> close() async {
    await _close(false, null);
  }

  Future<void> _close(bool interruptRunning, PgException? cause,
      {bool socketIsBroken = false}) async {
    if (!_isClosing) {
      _isClosing = true;

      if (interruptRunning) {
        _pending?.handleConnectionClosed(cause);
        if (!socketIsBroken) {
          _channel.sink.add(const TerminateMessage());
        }
      } else {
        // Wait for the previous operation to complete by using the lock
        await _operationLock.withResource(() {
          // Use lock to await earlier operations
          _channel.sink.add(const TerminateMessage());
        });
      }

      await Future.wait([_channel.sink.close(), _serverMessages.cancel()]);
      _closeSession();
    }
  }

  void _closeAfterError([PgException? cause]) {
    _close(true, cause);
  }
}

class _PreparedStatement extends Statement {
  final InternalQueryDescription _description;
  final String _name;
  final _PgSessionBase _session;

  _PreparedStatement(this._description, this._name, this._session);

  @override
  ResultStream bind(Object? parameters) {
    return _BoundStatement(
        this,
        _description.bindParameters(
          parameters,
          ignoreSuperfluous: _session._settings.ignoreSuperfluousParameters,
        ));
  }

  @override
  Future<Result> run(
    Object? parameters, {
    Duration? timeout,
  }) async {
    _session._connection._queryCount++;
    timeout ??= _session._settings.queryTimeout;
    final items = <ResultRow>[];
    final subscription = bind(parameters).listen(items.add);
    try {
      await subscription.asFuture().optionalTimeout(timeout);
    } finally {
      await subscription.cancel();
    }

    return Result(
      rows: items,
      affectedRows: await subscription.affectedRows,
      schema: await subscription.schema,
    );
  }

  @override
  Future<void> dispose() async {
    // Don't send a dispose message if the connection is already closed.
    if (!_session._connection._isClosing) {
      await _session._sendAndWaitForQuery<CloseCompleteMessage>(
          CloseMessage.statement(_name));
    }
  }
}

class _BoundStatement extends Stream<ResultRow> implements ResultStream {
  final _PreparedStatement statement;
  final List<TypedValue> parameters;

  _BoundStatement(this.statement, this.parameters);

  @override
  ResultStreamSubscription listen(void Function(ResultRow event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final controller = StreamController<ResultRow>();

    // ignore: cancel_subscriptions
    final subscription = controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    return _PgResultStreamSubscription(this, controller, subscription);
  }
}

class _PgResultStreamSubscription
    implements ResultStreamSubscription, _PendingOperation {
  @override
  final _PgSessionBase session;
  final StreamController<ResultRow> _controller;
  final StreamSubscription<ResultRow> _source;
  final bool ignoreRows;

  final _affectedRows = Completer<int>();
  int _affectedRowsSoFar = 0;
  final _schema = Completer<ResultSchema>();
  final _done = Completer<void>();
  ResultSchema? _resultSchema;

  @override
  PgConnectionImplementation get connection => session._connection;

  late final _portalName = 'p/${connection._portalCounter++}';
  final StackTrace _trace;

  _PgResultStreamSubscription(
      _BoundStatement statement, this._controller, this._source)
      : session = statement.statement._session,
        ignoreRows = false,
        _trace = StackTrace.current {
    _scheduleStatement(() async {
      connection._pending = this;

      connection._channel.sink.add(AggregatedClientMessage([
        BindMessage(
          statement.parameters
              .map((e) => connection._settings.typeRegistry.encodeValue(
                    e.value,
                    type: e.type,
                    encoding: connection.encoding,
                  ))
              .toList(),
          portalName: _portalName,
          statementName: statement.statement._name,
        ),
        DescribeMessage.portal(portalName: _portalName),
        ExecuteMessage(_portalName),
        SyncMessage(),
      ]));

      await _done.future;
    });
  }

  _PgResultStreamSubscription.simpleQueryProtocol(
    String sql,
    this.session,
    this._controller,
    this._source,
    this.ignoreRows, {
    void Function()? cleanup,
  }) : _trace = StackTrace.current {
    _scheduleStatement(() async {
      connection._pending = this;

      connection._channel.sink.add(QueryMessage(sql));
      await _done.future;
      cleanup?.call();
    });
  }

  void _scheduleStatement(Future<void> Function() sendAndWait) async {
    try {
      await session._withResource(sendAndWait);
    } catch (e, s) {
      // _withResource can fail if the connection or the session is already
      // closed. This error should be reported to the user!
      if (!_done.isCompleted) {
        _controller.addError(e, s);
        await _completeQuery();
      }
    }
  }

  @override
  Future<int> get affectedRows => _affectedRows.future;

  @override
  Future<ResultSchema> get schema => _schema.future;

  Future<void> _completeQuery() async {
    _done.complete();

    // Make sure the affectedRows and schema futures complete with something
    // after the query is done, even if we didn't get a row description
    // message.
    if (!_affectedRows.isCompleted) {
      _affectedRows.complete(_affectedRowsSoFar);
    }
    if (!_schema.isCompleted) {
      _schema.complete(ResultSchema(const []));
    }
    await _controller.close();
  }

  @override
  void handleConnectionClosed(PgException? dueToException) {
    if (dueToException != null) {
      _controller.addError(dueToException, _trace);
    }
    _completeQuery();
  }

  @override
  void handleError(PgException exception) {
    _controller.addError(exception, _trace);
  }

  @override
  Future<void> handleMessage(ServerMessage message) async {
    switch (message) {
      case BindCompleteMessage():
      case NoDataMessage():
        // Nothing to do!
        break;
      case RowDescriptionMessage():
        final schema = _resultSchema = ResultSchema([
          for (final field in message.fieldDescriptions)
            ResultSchemaColumn(
              typeOid: field.typeOid,
              type: session._connection._settings.typeRegistry
                  .resolveOid(field.typeOid),
              columnName: field.fieldName,
              columnOid: field.columnOid,
              tableOid: field.tableOid,
              isBinaryEncoding: field.isBinaryEncoding,
            ),
        ]);
        _schema.complete(schema);
      case DataRowMessage():
        if (!ignoreRows) {
          final schema = _resultSchema!;

          final columnValues = <Object?>[];
          for (var i = 0; i < message.values.length; i++) {
            final field = schema.columns[i];

            final input = message.values[i];
            final value =
                session._connection._settings.typeRegistry.decodeBytes(
              input,
              typeOid: field.typeOid,
              isBinary: field.isBinaryEncoding,
              encoding: session.encoding,
            );
            columnValues.add(value);
          }

          final row = ResultRow(schema: schema, values: columnValues);
          _controller.add(row);
        }
      case CommandCompleteMessage():
        // We can't complete _affectedRows directly after receiving the message
        // since, if multiple statements are running in a single SQL string,
        // we'll get this more than once.
        _affectedRowsSoFar += message.rowsAffected;
      case ReadyForQueryMessage():
        await _completeQuery();
      case CopyBothResponseMessage():
        // This message indicates a successful start for Streaming Replication.
        // Hence, in this context, the query is complete. And from here on,
        // the server will be streaming replication messages.
        // But if the connection was used after this point to execute further
        // queries, the server messages will be blocked.
        // TODO(osaxma): Prevent executing queries when Streaming Replication
        //               is ongoing
        await _completeQuery();
      default:
        // Unexpected message - either a severe bug in this package or in the
        // connection. We better close it.
        session._connection._closeAfterError();
    }
  }

  // Forwarding subscription interface to regular stream subscription from
  // controller

  @override
  Future<E> asFuture<E>([E? futureValue]) => _source.asFuture(futureValue);

  @override
  Future<void> cancel() => _source.cancel();

  @override
  bool get isPaused => _source.isPaused;

  @override
  void onData(void Function(ResultRow data)? handleData) {
    _source.onData(handleData);
  }

  @override
  void onDone(void Function()? handleDone) {
    _source.onDone(handleDone);
  }

  @override
  void onError(Function? handleError) {
    _source.onError(handleError);
  }

  @override
  void pause([Future<void>? resumeSignal]) {
    _source.pause(resumeSignal);
  }

  @override
  void resume() {
    _source.resume();
  }
}

class _Channels implements Channels {
  final PgConnectionImplementation _connection;

  final _activeListeners = <String, List<MultiStreamController<String>>>{};
  final _all = StreamController<Notification>.broadcast();

  // We are using the pg_notify function in a prepared select statement to
  // efficiently implement [notify].
  Completer<Statement>? _notifyStatement;

  _Channels(this._connection);

  @override
  Stream<Notification> get all => _all.stream;

  @override
  Stream<String> operator [](String channel) {
    return Stream.multi(
      (newListener) {
        newListener.onCancel = () => _unsubscribe(channel, newListener);

        final existingListeners =
            _activeListeners.putIfAbsent(channel, () => []);
        final needsSubscription = existingListeners.isEmpty;
        existingListeners.add(newListener);

        if (needsSubscription) {
          _subscribe(channel, newListener);
        }
      },
      isBroadcast: true,
    );
  }

  void _subscribe(String channel, MultiStreamController firstListener) {
    Future(() async {
      await _connection.execute(Sql('LISTEN ${_identifier(channel)}'),
          ignoreRows: true);
    }).onError<Object>((error, stackTrace) {
      _activeListeners[channel]?.remove(firstListener);

      firstListener
        ..addError(error, stackTrace)
        ..close();
    });
  }

  Future<void> _unsubscribe(
      String channel, MultiStreamController listener) async {
    final listeners = _activeListeners[channel]!..remove(listener);

    if (listeners.isEmpty) {
      _activeListeners.remove(channel);

      // Send unlisten command
      await _connection.execute(Sql('UNLISTEN ${_identifier(channel)}'),
          ignoreRows: true);
    }
  }

  void deliverNotification(NotificationResponseMessage msg) {
    _all.add(Notification(
      processId: msg.processId,
      channel: msg.channel,
      payload: msg.payload,
    ));
    final listeners = _activeListeners[msg.channel] ?? const [];

    for (final listener in listeners) {
      listener.add(msg.payload);
    }
  }

  @override
  Future<void> cancelAll() async {
    await _connection.execute(Sql('UNLISTEN *'));

    for (final entry in _activeListeners.values) {
      for (final listener in entry) {
        await listener.close();
      }
    }
  }

  @override
  Future<void> notify(String channel, [String? payload]) async {
    final statementCompleter = _notifyStatement ??= Completer<Statement>()
      ..complete(Future(() async {
        return _connection.prepare(
            Sql(r'SELECT pg_notify($1, $2)', types: [Type.text, Type.text]));
      }));
    final statement = await statementCompleter.future;

    await statement.run([channel, payload]);
  }
}

class _RegularSession extends _PgSessionBase {
  @override
  final PgConnectionImplementation _connection;
  @override
  final ResolvedSessionSettings _settings;

  _RegularSession(this._connection, this._settings);
}

class _TransactionSession extends _PgSessionBase implements TxSession {
  @override
  final PgConnectionImplementation _connection;
  @override
  final ResolvedTransactionSettings _settings;

  bool _closing = false;
  PgException? _transactionException;

  _TransactionSession(this._connection, this._settings);

  /// Sends the [command] and, before releasing the internal connection lock,
  /// marks the session as closed.
  ///
  /// This prevents other pending operations on the transaction that haven't
  /// been awaited from running.
  Future<void> _sendAndMarkClosed(String command) async {
    _closing = true;
    final controller = StreamController<ResultRow>();
    final items = <ResultRow>[];

    final querySubscription = _PgResultStreamSubscription.simpleQueryProtocol(
      command,
      this,
      controller,
      controller.stream.listen(items.add),
      true,
      cleanup: () {
        _closeSession();
        _connection._activeTransaction = null;
      },
    );
    await querySubscription.asFuture();
    await querySubscription.cancel();
  }

  @override
  Future<void> rollback() async {
    await _sendAndMarkClosed('ROLLBACK;');
  }

  bool get mayCommit =>
      !_closing &&
      _connection._activeTransaction == this &&
      _transactionException == null;
}

abstract class _PendingOperation {
  final _PgSessionBase session;

  PgConnectionImplementation get connection => session._connection;

  _PendingOperation(this.session);

  /// Handle the connection being closed, either because it has been closed
  /// explicitly or because a fatal exception is interrupting the connection.
  void handleConnectionClosed(PgException? dueToException);

  /// Handles an [ErrorResponseMessage] in an exception form. If the exception
  /// is severe enough to close the connection, [handleConnectionClosed] will
  /// be called instead.
  void handleError(PgException exception);

  /// Handles a message from the postgres server. The [message] will never be
  /// a [ErrorResponseMessage] - these are delivered through [handleError] or
  /// [handleConnectionClosed].
  Future<void> handleMessage(ServerMessage message);
}

class _WaitForMessage<T extends ServerMessage> extends _PendingOperation {
  final StackTrace trace;
  final doneWithOperation = Completer<void>();
  async.Result<T>? result;

  _WaitForMessage(super.session, this.trace);

  @override
  void handleConnectionClosed(PgException? dueToException) {
    result = async.Result.error(
      dueToException ??
          PgException('Connection closed while waiting for message'),
      trace,
    );
    doneWithOperation.complete();
  }

  @override
  void handleError(PgException exception) {
    result = async.Result.error(exception, trace);
    // We're not done yet! Exceptions delivered through handleError aren't
    // fatal, so we'll continue waiting for a ReadyForQuery message.
  }

  @override
  Future<void> handleMessage(ServerMessage message) async {
    if (message is T) {
      result = async.Result.value(message);
      // Don't complete, we're still waiting for a ready for query message.
    } else if (message is ReadyForQueryMessage) {
      // This is the message we've been waiting for, the server is signalling
      // that it's ready for another message - so we can release the lock.
      doneWithOperation.complete();
    } else {
      result =
          async.Result.error(StateError('Unexpected message $message'), trace);

      // If we get here, we clearly have a misunderstanding about the
      // protocol or something is very seriously broken. Treat this as a
      // critical flaw and close the connection as well.
      session._connection._closeAfterError();
    }
  }
}

class _AuthenticationProcedure extends _PendingOperation {
  final bool _hasSecureTransport;

  final StackTrace _trace;
  final _done = Completer<void>();

  late PostgresAuthenticator _authenticator;

  _AuthenticationProcedure(super.connection, this._hasSecureTransport)
      : _trace = StackTrace.current;

  void _initializeAuthenticate(
      AuthenticationMessage message, AuthenticationScheme scheme) {
    final authConnection = PostgresAuthConnection(
      connection._endpoint.username ?? '',
      connection._endpoint.password ?? '',
      connection._channel.sink.add,
    );

    _authenticator = createAuthenticator(authConnection, scheme)
      ..onMessage(message);
  }

  @override
  void handleConnectionClosed(PgException? dueToException) {
    _done.completeError(
      dueToException ?? PgException('Connection closed during authentication'),
      _trace,
    );
  }

  @override
  void handleError(PgException exception) {
    _done.completeError(exception, _trace);

    // If the authentication procedure fails, the connection is unusable - so we
    // might as well close it right away.
    session._connection._closeAfterError();
  }

  @override
  Future<void> handleMessage(ServerMessage message) async {
    if (message is ErrorResponseMessage) {
      _done.completeError(ServerException.fromFields(message.fields), _trace);
    } else if (message is AuthenticationMessage) {
      switch (message.type) {
        case AuthenticationMessageType.ok:
          break;
        case AuthenticationMessageType.md5Password:
          _initializeAuthenticate(message, AuthenticationScheme.md5);
          break;
        case AuthenticationMessageType.clearTextPassword:
          if (!_hasSecureTransport &&
              !connection._settings.sslMode.allowCleartextPassword) {
            _done.completeError(
              ServerException('Refused to send clear text password to server'),
              _trace,
            );
            return;
          }

          _initializeAuthenticate(message, AuthenticationScheme.clear);
          break;
        case AuthenticationMessageType.sasl:
          _initializeAuthenticate(message, AuthenticationScheme.scramSha256);
          break;
        case AuthenticationMessageType.saslContinue:
        case AuthenticationMessageType.saslFinal:
          _authenticator.onMessage(message);
          break;
        default:
          _done.completeError(PgException('Unhandled auth mechanism'), _trace);
      }
    } else if (message is ReadyForQueryMessage) {
      _done.complete();
    }
  }
}

extension on PgException {
  bool get willAbortConnection {
    return severity == Severity.fatal || severity == Severity.panic;
  }
}

extension FutureExt<R> on Future<R> {
  Future<R> optionalTimeout(Duration? duration) {
    if (duration == null) {
      return this;
    }
    return timeout(duration);
  }
}

extension on TransactionSettings {
  bool get shouldExpandBegin =>
      isolationLevel != null || accessMode != null || deferrable != null;

  void expandBegin(StringBuffer sb) {
    if (isolationLevel != null) {
      sb.write(isolationLevel!.queryPart);
    }
    if (accessMode != null) {
      sb.write(accessMode!.queryPart);
    }
    if (deferrable != null) {
      sb.write(deferrable!.queryPart);
    }
  }
}
