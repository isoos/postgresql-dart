import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:charcode/ascii.dart';
import 'package:collection/collection.dart';
import 'package:pool/pool.dart';
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:stream_channel/stream_channel.dart';

import '../auth/auth.dart';
import '../binary_codec.dart';
import '../exceptions.dart';
import '../replication.dart';
import '../text_codec.dart';
import 'protocol.dart';
import 'query_description.dart';

const _debugLog = false;

String identifier(String source) {
  // To avoid complex ambiguity rules, we always wrap identifier in double
  // quotes. That means the only character we need to escape are double quotes
  // in the source.
  final escaped = source.replaceAll('"', '""');
  return '"$escaped"';
}

class _ResolvedSettings {
  final PgEndpoint endpoint;
  final PgSessionSettings? settings;

  final String username;
  final String password;

  final Duration connectTimeout;
  //final Duration queryTimeout;
  final String timeZone;
  final Encoding encoding;

  final ReplicationMode replicationMode;
  final QueryMode queryMode;

  final StreamChannelTransformer<BaseMessage, BaseMessage>? transformer;

  final bool allowSuperfluousParameters;

  _ResolvedSettings(
    this.endpoint,
    this.settings,
  )   : username = endpoint.username ?? 'postgres',
        password = endpoint.password ?? 'postgres',
        connectTimeout =
            settings?.connectTimeout ?? const Duration(seconds: 15),
        //queryTimeout = settings?.connectTimeout ?? const Duration(minutes: 5),
        timeZone = settings?.timeZone ?? 'UTC',
        encoding = settings?.encoding ?? utf8,
        transformer = settings?.transformer,
        replicationMode = settings?.replicationMode ?? ReplicationMode.none,
        queryMode = settings?.queryMode ?? QueryMode.extended,
        allowSuperfluousParameters =
            settings?.allowSuperfluousParameters ?? false;

  bool onBadSslCertificate(X509Certificate certificate) {
    return settings?.onBadSslCertificate?.call(certificate) ?? false;
  }
}

abstract class _PgSessionBase implements PgSession {
  /// The lock to guard operations that must run sequentially, like sending
  /// RPC messages to the postgres server and waiting for them to complete.
  ///
  /// Each session base has its own operation lock, but child sessions hold the
  /// parent lock while they are active. For instance, when starting a
  /// transaction,the [_operationLock] of the connection is held until the
  /// transaction completes. This ensures that no other statement can use the
  /// connection in the meantime.
  final Pool _operationLock = Pool(1);

  bool _sessionClosed = false;

  PgConnectionImplementation get _connection;
  Encoding get encoding => _connection._settings.encoding;

  void _checkActive() {
    if (_sessionClosed) {
      throw PostgreSQLException(
          'Session or transaction has already finished, did you forget to await a statement?');
    } else if (_connection._isClosing) {
      throw PostgreSQLException('Connection is closing down');
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
            Result.error(StateError('Operation did not complete'), trace);

        return effectiveResult.asFuture;
      });
    });
  }

  @override
  Future<PgResult> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async {
    final description = InternalQueryDescription.wrap(query);
    final variables = description.bindParameters(
      parameters,
      allowSuperfluous: _connection._settings.allowSuperfluousParameters,
    );

    late final bool isSimple;
    if (queryMode != null) {
      isSimple = queryMode == QueryMode.simple;
    } else {
      isSimple = _connection._settings.queryMode == QueryMode.simple;
    }

    if (isSimple && variables.isNotEmpty) {
      throw PostgreSQLException('Parameterized queries are not supported when '
          'using the Simple Query Protocol');
    }

    if (isSimple || (ignoreRows && variables.isEmpty)) {
      // Great, we can just run a simple query.
      final controller = StreamController<PgResultRow>();
      final items = <PgResultRow>[];

      final querySubscription = _PgResultStreamSubscription.simpleQueryProtocol(
        description.transformedSql,
        this,
        controller,
        controller.stream.listen(items.add),
        ignoreRows,
      );
      try {
        await querySubscription.asFuture().optionalTimeout(timeout);
        return PgResult(items, await querySubscription.affectedRows,
            await querySubscription.schema);
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
  Future<PgStatement> prepare(Object query) async => await _prepare(query);

  Future<_PreparedStatement> _prepare(
    Object query, {
    Duration? timeout,
  }) async {
    final conn = _connection;
    final name = 's/${conn._statementCounter++}';
    final description = InternalQueryDescription.wrap(query);

    await _sendAndWaitForQuery<ParseCompleteMessage>(ParseMessage(
      description.transformedSql,
      statementName: name,
      types: description.parameterTypes,
    )).optionalTimeout(timeout);

    return _PreparedStatement(description, name, this);
  }
}

class PgConnectionImplementation extends _PgSessionBase
    implements PgConnection {
  static Future<PgConnectionImplementation> connect(
    PgEndpoint endpoint, {
    PgSessionSettings? sessionSettings,
  }) async {
    final settings = _ResolvedSettings(endpoint, sessionSettings);
    var channel = await _connect(settings);

    if (_debugLog) {
      channel = channel.transform(StreamChannelTransformer(
        StreamTransformer.fromHandlers(
          handleData: (msg, sink) {
            print('[in] $msg');
            sink.add(msg);
          },
        ),
        StreamSinkTransformer.fromHandlers(handleData: (msg, sink) {
          print('[out] $msg');
          sink.add(msg);
        }),
      ));
    }

    if (settings.transformer != null) {
      channel = channel.transform(settings.transformer!);
    }

    final connection = PgConnectionImplementation._(channel, settings);
    await connection._startup();
    return connection;
  }

  static Future<StreamChannel<BaseMessage>> _connect(
    _ResolvedSettings settings,
  ) async {
    Socket socket;

    final host = settings.endpoint.host;
    final port = settings.endpoint.port;

    if (settings.endpoint.isUnixSocket) {
      socket =
          await Socket.connect(host, port, timeout: settings.connectTimeout);
    } else {
      socket =
          await Socket.connect(host, port, timeout: settings.connectTimeout);
    }

    final sslCompleter = Completer<int>.sync();
    // ignore: cancel_subscriptions
    final subscription = socket.listen(
      (data) {
        if (data.length != 1) {
          sslCompleter.completeError(PostgreSQLException(
              'Could not initialize SSL connection, received unknown byte stream.'));
          return;
        }

        sslCompleter.complete(data.first);
      },
      onDone: () => sslCompleter.completeError(PostgreSQLException(
          'Could not initialize SSL connection, connection closed during handshake.')),
      onError: sslCompleter.completeError,
    );

    // Query if SSL is possible by sending a SSLRequest message
    final byteBuffer = ByteData(8);
    byteBuffer.setUint32(0, 8);
    byteBuffer.setUint32(4, 80877103);
    socket.add(byteBuffer.buffer.asUint8List());

    final byte = await sslCompleter.future.timeout(settings.connectTimeout);

    Stream<Uint8List> adaptedStream;

    if (byte == $S) {
      // SSL is supported, upgrade!
      subscription.pause();

      socket = await SecureSocket.secure(
        socket,
        onBadCertificate: settings.onBadSslCertificate,
      ).timeout(settings.connectTimeout);

      // We can listen to the secured socket again, the existing subscription is
      // ignored.
      adaptedStream = socket;
    } else {
      // This server does not support SSL
      if (settings.endpoint.requireSsl) {
        throw PostgreSQLException(
            'Server does not support SSL, but it was required.');
      }

      // We've listened to the stream already and sockets are single-subscription
      // streams. Expose it as a new stream.
      adaptedStream = SubscriptionStream(subscription);
    }

    final outgoingSocket = StreamSinkExtensions(socket).transform<Uint8List>(
        StreamSinkTransformer.fromHandlers(handleDone: (out) {
      // As per the stream channel's guarantees, closing the sink should close
      // the channel in both directions.
      socket.destroy();
      return out.close();
    }));

    return StreamChannel<List<int>>(adaptedStream, outgoingSocket)
        .transform(messageTransformer(settings.encoding));
  }

  final StreamChannel<BaseMessage> _channel;
  late final StreamSubscription<BaseMessage> _serverMessages;
  bool _isClosing = false;

  final _ResolvedSettings _settings;

  _PendingOperation? _pending;
  // Errors happening while a transaction is active will roll back the
  // transaction and should be reporte to the user.
  _TransactionSession? _activeTransaction;

  final Map<String, String> _parameters = {};

  var _statementCounter = 0;
  var _portalCounter = 0;

  late final _Channels _channels = _Channels(this);

  @override
  PgChannels get channels => _channels;

  @override
  PgConnectionImplementation get _connection => this;

  PgConnectionImplementation._(this._channel, this._settings) {
    _serverMessages = _channel.stream.listen(_handleMessage);
  }

  Future<void> _startup() {
    return _withResource(() {
      final result = _pending = _AuthenticationProcedure(this);

      _channel.sink.add(StartupMessage(
        _settings.endpoint.database,
        _settings.timeZone,
        username: _settings.username,
        replication: _settings.replicationMode,
      ));

      return result._done.future;
    });
  }

  Future<void> _handleMessage(BaseMessage message) async {
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
        final exception = PostgreSQLException.fromFields(message.fields);

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
  Future<R> run<R>(Future<R> Function(PgSession session) fn) {
    // Unlike runTx, this doesn't need any locks. An active transaction changes
    // the state of the connection, this method does not. If methods requiring
    // locks are called by [fn], these methods will aquire locks as needed.
    return Future.sync(() => fn(this));
  }

  @override
  Future<R> runTx<R>(Future<R> Function(PgSession session) fn) {
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
          _connection._activeTransaction = _TransactionSession(this);
      await transaction.execute(PgSql('BEGIN;'), queryMode: QueryMode.simple);

      try {
        final result = await fn(transaction);
        await transaction._sendAndMarkClosed('COMMIT;');

        // If we have received an error while the transaction was active, it
        // will always be rolled back.
        if (transaction._transactionException
            case final PostgreSQLException e) {
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

  Future<void> _close(bool interruptRunning, PostgreSQLException? cause) async {
    if (!_isClosing) {
      _isClosing = true;

      if (interruptRunning) {
        _pending?.handleConnectionClosed(cause);
        _channel.sink.add(const TerminateMessage());
      } else {
        // Wait for the previous operation to complete by using the lock
        await _operationLock.withResource(() {
          // Use lock to await earlier operations
          _channel.sink.add(const TerminateMessage());
        });
      }

      await Future.wait([_channel.sink.close(), _serverMessages.cancel()]);
    }
  }

  void _closeAfterError([PostgreSQLException? cause]) {
    _close(true, cause);
  }
}

class _PreparedStatement extends PgStatement {
  final InternalQueryDescription _description;
  final String _name;
  final _PgSessionBase _session;

  _PreparedStatement(this._description, this._name, this._session);

  @override
  PgResultStream bind(Object? parameters) {
    return _BoundStatement(
        this,
        _description.bindParameters(
          parameters,
          allowSuperfluous:
              _session._connection._settings.allowSuperfluousParameters,
        ));
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

class _BoundStatement extends Stream<PgResultRow> implements PgResultStream {
  final _PreparedStatement statement;
  final List<PgTypedParameter> parameters;

  _BoundStatement(this.statement, this.parameters);

  @override
  PgResultStreamSubscription listen(void Function(PgResultRow event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final controller = StreamController<PgResultRow>();

    // ignore: cancel_subscriptions
    final subscription = controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    return _PgResultStreamSubscription(this, controller, subscription);
  }
}

class _PgResultStreamSubscription
    implements PgResultStreamSubscription, _PendingOperation {
  @override
  final _PgSessionBase session;
  final StreamController<PgResultRow> _controller;
  final StreamSubscription<PgResultRow> _source;
  final bool ignoreRows;

  final Completer<int> _affectedRows = Completer();
  int _affectedRowsSoFar = 0;
  final Completer<PgResultSchema> _schema = Completer();
  final Completer<void> _done = Completer();
  PgResultSchema? _resultSchema;

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
          statement.parameters,
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
  Future<PgResultSchema> get schema => _schema.future;

  Future<void> _completeQuery() async {
    _done.complete();

    // Make sure the affectedRows and schema futures complete with something
    // after the query is done, even if we didn't get a row description
    // message.
    if (!_affectedRows.isCompleted) {
      _affectedRows.complete(_affectedRowsSoFar);
    }
    if (!_schema.isCompleted) {
      _schema.complete(PgResultSchema(const []));
    }
    await _controller.close();
  }

  @override
  void handleConnectionClosed(PostgreSQLException? dueToException) {
    if (dueToException != null) {
      _controller.addError(dueToException, _trace);
    }
    _completeQuery();
  }

  @override
  void handleError(PostgreSQLException exception) {
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
        final schema = _resultSchema = PgResultSchema([
          for (final field in message.fieldDescriptions)
            PgResultColumn(
              type: PgDataType.byTypeOid[field.typeOid] ?? PgDataType.byteArray,
              columnName: field.fieldName,
              columnOid: field.columnOid,
              tableOid: field.tableOid,
              binaryEncoding: field.isBinaryEncoding,
            ),
        ]);
        _schema.complete(schema);
      case DataRowMessage():
        if (!ignoreRows) {
          final schema = _resultSchema!;

          final columnValues = <Object?>[];
          for (var i = 0; i < message.values.length; i++) {
            final field = schema.columns[i];

            final type = field.type;
            late final dynamic value;
            if (field.binaryEncoding) {
              value = PostgresBinaryDecoder(type)
                  .convert(message.values[i], session.encoding);
            } else {
              value = PostgresTextDecoder(type)
                  .convert(message.values[i], session.encoding);
            }

            columnValues.add(value);
          }

          final row = _ResultRow(schema, columnValues);
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
  void onData(void Function(PgResultRow data)? handleData) {
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

class _Channels implements PgChannels {
  final PgConnectionImplementation _connection;

  final Map<String, List<MultiStreamController<String>>> _activeListeners = {};
  final StreamController<PgNotification> _all = StreamController.broadcast();

  // We are using the pg_notify function in a prepared select statement to
  // efficiently implement [notify].
  Completer<PgStatement>? _notifyStatement;

  _Channels(this._connection);

  @override
  Stream<PgNotification> get all => _all.stream;

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
      await _connection.execute(PgSql('LISTEN ${identifier(channel)}'),
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
      await _connection.execute(PgSql('UNLISTEN ${identifier(channel)}'),
          ignoreRows: true);
    }
  }

  void deliverNotification(NotificationResponseMessage msg) {
    _all.add(
        (processId: msg.processID, channel: msg.channel, payload: msg.payload));
    final listeners = _activeListeners[msg.channel] ?? const [];

    for (final listener in listeners) {
      listener.add(msg.payload);
    }
  }

  @override
  Future<void> cancelAll() async {
    await _connection.execute(PgSql('UNLISTEN *'));

    for (final entry in _activeListeners.values) {
      for (final listener in entry) {
        await listener.close();
      }
    }
  }

  @override
  Future<void> notify(String channel, [String? payload]) async {
    final statementCompleter = _notifyStatement ??= Completer()
      ..complete(Future(() async {
        return _connection.prepare(PgSql(r'SELECT pg_notify($1, $2)',
            types: [PgDataType.text, PgDataType.text]));
      }));
    final statement = await statementCompleter.future;

    await statement.run([channel, payload]);
  }
}

class _TransactionSession extends _PgSessionBase {
  @override
  final PgConnectionImplementation _connection;

  PostgreSQLException? _transactionException;

  _TransactionSession(this._connection);

  /// Sends the [command] and, before releasing the internal connection lock,
  /// marks the session as closed.
  ///
  /// This prevents other pending operations on the transaction that haven't
  /// been awaited from running.
  Future<void> _sendAndMarkClosed(String command) async {
    final controller = StreamController<PgResultRow>();
    final items = <PgResultRow>[];

    final querySubscription = _PgResultStreamSubscription.simpleQueryProtocol(
      command,
      this,
      controller,
      controller.stream.listen(items.add),
      true,
      cleanup: () {
        _sessionClosed = true;
        _connection._activeTransaction = null;
      },
    );
    await querySubscription.asFuture();
    await querySubscription.cancel();
  }
}

abstract class _PendingOperation {
  final _PgSessionBase session;

  PgConnectionImplementation get connection => session._connection;

  _PendingOperation(this.session);

  /// Handle the connection being closed, either because it has been closed
  /// explicitly or because a fatal exception is interrupting the connection.
  void handleConnectionClosed(PostgreSQLException? dueToException);

  /// Handles an [ErrorResponseMessage] in an exception form. If the exception
  /// is severe enough to close the connection, [handleConnectionClosed] will
  /// be called instead.
  void handleError(PostgreSQLException exception);

  /// Handles a message from the postgres server. The [message] will never be
  /// a [ErrorResponseMessage] - these are delivered through [handleError] or
  /// [handleConnectionClosed].
  Future<void> handleMessage(ServerMessage message);
}

class _ResultRow extends UnmodifiableListView<Object?> implements PgResultRow {
  @override
  final PgResultSchema schema;

  _ResultRow(this.schema, super.source);
}

class _WaitForMessage<T extends ServerMessage> extends _PendingOperation {
  final StackTrace trace;
  final doneWithOperation = Completer<void>.sync();
  Result<T>? result;

  _WaitForMessage(super.session, this.trace);

  @override
  void handleConnectionClosed(PostgreSQLException? dueToException) {
    result = Result.error(
      dueToException ??
          PostgreSQLException('Connection closed while waiting for message'),
      trace,
    );
    doneWithOperation.complete();
  }

  @override
  void handleError(PostgreSQLException exception) {
    result = Result.error(exception, trace);
    // We're not done yet! Exceptions delivered through handleError aren't
    // fatal, so we'll continue waiting for a ReadyForQuery message.
  }

  @override
  Future<void> handleMessage(ServerMessage message) async {
    if (message is T) {
      result = Result.value(message);
      // Don't complete, we're still waiting for a ready for query message.
    } else if (message is ReadyForQueryMessage) {
      // This is the message we've been waiting for, the server is signalling
      // that it's ready for another message - so we can release the lock.
      doneWithOperation.complete();
    } else {
      result = Result.error(StateError('Unexpected message $message'), trace);

      // If we get here, we clearly have a misunderstanding about the
      // protocol or something is very seriously broken. Treat this as a
      // critical flaw and close the connection as well.
      session._connection._closeAfterError();
    }
  }
}

class _AuthenticationProcedure extends _PendingOperation {
  final StackTrace _trace;
  final Completer<void> _done = Completer();

  late PostgresAuthenticator _authenticator;

  _AuthenticationProcedure(super.connection) : _trace = StackTrace.current;

  void _initializeAuthenticate(
      AuthenticationMessage message, AuthenticationScheme scheme) {
    final authConnection = PostgresAuthConnection(
      connection._settings.username,
      connection._settings.password,
      connection._channel.sink.add,
    );

    _authenticator = createAuthenticator(authConnection, scheme)
      ..onMessage(message);
  }

  @override
  void handleConnectionClosed(PostgreSQLException? dueToException) {
    _done.completeError(
      dueToException ??
          PostgreSQLException('Connection closed during authentication'),
      _trace,
    );
  }

  @override
  void handleError(PostgreSQLException exception) {
    _done.completeError(exception, _trace);

    // If the authentication procedure fails, the connection is unusable - so we
    // might as well close it right away.
    session._connection._closeAfterError();
  }

  @override
  Future<void> handleMessage(ServerMessage message) async {
    if (message is ErrorResponseMessage) {
      _done.completeError(
          PostgreSQLException.fromFields(message.fields), _trace);
    } else if (message is AuthenticationMessage) {
      switch (message.type) {
        case AuthenticationMessage.KindOK:
          break;
        case AuthenticationMessage.KindMD5Password:
          _initializeAuthenticate(message, AuthenticationScheme.md5);
          break;
        case AuthenticationMessage.KindClearTextPassword:
          if (!connection._settings.endpoint.allowCleartextPassword) {
            _done.completeError(
              PostgreSQLException(
                  'Refused to send clear text password to server',
                  stackTrace: StackTrace.current),
              _trace,
            );
            return;
          }

          _initializeAuthenticate(message, AuthenticationScheme.clear);
          break;
        case AuthenticationMessage.KindSASL:
          _initializeAuthenticate(message, AuthenticationScheme.scramSha256);
          break;
        case AuthenticationMessage.KindSASLContinue:
        case AuthenticationMessage.KindSASLFinal:
          _authenticator.onMessage(message);
          break;
        default:
          _done.completeError(
              PostgreSQLException('Unhandled auth mechanism'), _trace);
      }
    } else if (message is ReadyForQueryMessage) {
      _done.complete();
    }
  }
}

extension on PostgreSQLException {
  bool get willAbortConnection {
    return severity == PgSeverity.fatal || severity == PgSeverity.panic;
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
