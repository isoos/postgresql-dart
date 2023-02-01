import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:charcode/ascii.dart';
import 'package:collection/collection.dart';
import 'package:pool/pool.dart';
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:postgres/src/query.dart';
import 'package:stream_channel/stream_channel.dart';

import '../auth/auth.dart';
import '../connection.dart' show PostgreSQLException;
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
  final Duration queryTimeout;
  final String timeZone;
  final Encoding encoding;

  final StreamChannelTransformer<BaseMessage, BaseMessage>? transformer;

  _ResolvedSettings(
    this.endpoint,
    this.settings,
  )   : username = endpoint.username ?? 'postgres',
        password = endpoint.password ?? 'postgres',
        connectTimeout =
            settings?.connectTimeout ?? const Duration(seconds: 15),
        queryTimeout = settings?.connectTimeout ?? const Duration(minutes: 5),
        timeZone = settings?.timeZone ?? 'UTC',
        encoding = settings?.encoding ?? utf8,
        transformer = settings?.transformer;

  bool onBadSslCertificate(X509Certificate certificate) {
    return settings?.onBadSslCertificate?.call(certificate) ?? false;
  }
}

class PgConnectionImplementation implements PgConnection {
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
        .transform(messageTransformer);
  }

  final StreamChannel<BaseMessage> _channel;
  late final StreamSubscription<BaseMessage> _serverMessages;

  final _ResolvedSettings _settings;

  final Pool _operationLock = Pool(1);
  _PendingOperation? _pending;

  final Map<String, String> _parameters = {};

  var _statementCounter = 0;
  var _portalCounter = 0;

  late final _Channels _channels = _Channels(this);

  @override
  PgChannels get channels => _channels;

  PgConnectionImplementation._(this._channel, this._settings) {
    _serverMessages = _channel.stream.listen(_handleMessage);
  }

  Future<void> _startup() {
    return _operationLock.withResource(() {
      final result = _pending = _AuthenticationProcedure(this);

      _channel.sink.add(StartupMessage(
        _settings.endpoint.database,
        _settings.timeZone,
        username: _settings.username,
        // todo: Replication
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
      } else if (message is BackendKeyMessage) {
        // ignore for now
      } else if (message is NotificationResponseMessage) {
        _channels.deliverNotification(message);
      } else if (_pending != null) {
        await _pending!.handleMessage(message);
      }
    } finally {
      _serverMessages.resume();
    }
  }

  Future<T> _sendAndWaitForQuery<T extends ServerMessage>(ClientMessage send) {
    final trace = StackTrace.current;

    return _operationLock.withResource(() {
      _channel.sink.add(AggregatedClientMessage([send, const SyncMessage()]));

      final completer = Completer<T>();
      final syncComplete = Completer<void>.sync();

      _pending = _CallbackOperation(this, (message) async {
        if (message is T) {
          completer.complete(message);
        } else if (message is ErrorResponseMessage) {
          completer.completeError(
              PostgreSQLException.fromFields(message.fields), trace);
        } else if (message is ReadyForQueryMessage) {
          if (!completer.isCompleted) {
            completer.completeError(
                StateError('Operation did not complete'), trace);
          }

          syncComplete.complete();
        } else {
          completer.completeError(
              StateError('Unexpected message $message'), trace);
        }
      });

      return syncComplete.future
          .whenComplete(() => _pending = null)
          .then((value) => completer.future);
    });
  }

  @override
  Future<PgStatement> prepare(Object query, {Duration? timeout}) async {
    final name = 's/${_statementCounter++}';
    final description = InternalQueryDescription.wrap(query);

    await _sendAndWaitForQuery<ParseCompleteMessage>(ParseMessage(
      description.transformedSql,
      statementName: name,
      types: description.parameterTypes,
    ));

    return _PreparedStatement(description, name, this);
  }

  @override
  Future<PgResult> execute(Object query,
      {Object? parameters, Duration? timeout}) async {
    final description = InternalQueryDescription.wrap(query);
    final variables = description.bindParameters(parameters);

    if (variables.isNotEmpty) {
      // The simple query protocol does not support variables, so we have to
      // prepare a statement explicitly.
      final prepared = await prepare(description, timeout: timeout);
      try {
        return prepared.run(variables, timeout: timeout);
      } finally {
        await prepared.dispose();
      }
    } else {
      // Great, we can just run a simple query.
      final controller = StreamController<PgResultRow>();
      final items = <PgResultRow>[];

      final querySubscription = _PgResultStreamSubscription.simpleQuery(
        description.transformedSql,
        this,
        controller,
        controller.stream.listen(items.add),
      );
      await querySubscription.asFuture();
      await querySubscription.cancel();

      return PgResult(items, await querySubscription.affectedRows,
          await querySubscription.schema);
    }
  }

  @override
  Future<R> run<R>(Future<R> Function(PgSession session) fn) {
    // TODO: implement run
    throw UnimplementedError();
  }

  @override
  Future<R> runTx<R>(Future<R> Function(PgSession session) fn) {
    // TODO: implement runTx
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {
    await _operationLock.withResource(() {
      // Use lock to await earlier operations
      _channel.sink.add(const TerminateMessage());
    });

    await Future.wait([_channel.sink.close(), _serverMessages.cancel()]);
  }
}

class _PreparedStatement extends PgStatement {
  final InternalQueryDescription _description;
  final String _name;
  final PgConnectionImplementation _connection;

  _PreparedStatement(this._description, this._name, this._connection);

  @override
  PgResultStream bind(Object? parameters) {
    return _BoundStatement(this, _description.bindParameters(parameters));
  }

  @override
  Future<void> dispose() async {
    await _connection._sendAndWaitForQuery<CloseCompleteMessage>(
        CloseMessage.statement(_name));
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
  final PgConnectionImplementation connection;
  final StreamController<PgResultRow> _controller;
  final StreamSubscription<PgResultRow> _source;

  final Completer<int> _affectedRows = Completer();
  final Completer<PgResultSchema> _schema = Completer();
  final Completer<void> _done = Completer();
  PgResultSchema? _resultSchema;

  late final _portalName = 'p/${connection._portalCounter++}';

  _PgResultStreamSubscription(
      _BoundStatement statement, this._controller, this._source)
      : connection = statement.statement._connection {
    connection._operationLock.withResource(() async {
      connection._pending = this;

      connection._channel.sink.add(AggregatedClientMessage([
        BindMessage(
          [
            for (final parameter in statement.parameters)
              ParameterValue.binary(parameter.value, parameter.type)
          ],
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

  _PgResultStreamSubscription.simpleQuery(
      String sql, this.connection, this._controller, this._source) {
    connection._operationLock.withResource(() async {
      connection._pending = this;

      connection._channel.sink.add(QueryMessage(sql));
      await _done.future;
    });
  }

  @override
  Future<int> get affectedRows => _affectedRows.future;

  @override
  Future<PgResultSchema> get schema => _schema.future;

  void _error(Object error) {
    if (!_schema.isCompleted) _schema.completeError(error);
    if (!_affectedRows.isCompleted) _affectedRows.completeError(error);

    _controller.addError(error);
  }

  @override
  Future<void> handleMessage(ServerMessage message) async {
    if (message is ErrorResponseMessage) {
      final error = AsyncError(
          PostgreSQLException.fromFields(message.fields), StackTrace.current);
      _error(error);
    } else if (message is BindCompleteMessage) {
      // Nothing to do
    } else if (message is RowDescriptionMessage) {
      final schema = _resultSchema = PgResultSchema([
        for (final field in message.fieldDescriptions)
          PgResultColumn(
            type: PgDataType.byTypeOid[field.typeId] ?? PgDataType.byteArray,
            tableName: field.tableName,
            columnName: field.columnName,
            columnOid: field.columnID,
            tableOid: field.tableID,
            binaryEncoding: field.formatCode != 0,
          ),
      ]);
      _schema.complete(schema);
    } else if (message is DataRowMessage) {
      final schema = _resultSchema!;

      final columnValues = <Object?>[];
      for (var i = 0; i < message.values.length; i++) {
        final field = schema.columns[i];

        final type = field.type;
        final codec = field.binaryEncoding ? type.binaryCodec : type.textCodec;

        columnValues.add(codec.decode(message.values[i]));
      }

      final row = _ResultRow(schema, columnValues);
      _controller.add(row);
    } else if (message is CommandCompleteMessage) {
      _affectedRows.complete(message.rowsAffected);
    } else if (message is ReadyForQueryMessage) {
      _done.complete();
      await _controller.close();
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

  // We are using the pg_notify function in a prepared select statement to
  // efficiently implement [notify].
  Completer<PgStatement>? _notifyStatement;

  _Channels(this._connection);

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
      await _connection.execute(PgSql('LISTEN ${identifier(channel)}'));
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
      await _connection.execute(PgSql('UNLISTEN ${identifier(channel)}'));
    }
  }

  void deliverNotification(NotificationResponseMessage msg) {
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

abstract class _PendingOperation {
  final PgConnectionImplementation connection;

  _PendingOperation(this.connection);

  Future<void> handleMessage(ServerMessage message);
}

class _ResultRow extends UnmodifiableListView<Object?> implements PgResultRow {
  @override
  final PgResultSchema schema;

  _ResultRow(this.schema, super.source);
}

class _CallbackOperation extends _PendingOperation {
  final Future<void> Function(ServerMessage message) handle;

  _CallbackOperation(super.connection, this.handle);

  @override
  Future<void> handleMessage(ServerMessage message) => handle(message);
}

class _AuthenticationProcedure extends _PendingOperation {
  final Completer<void> _done = Completer();

  late PostgresAuthenticator _authenticator;

  _AuthenticationProcedure(super.connection);

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
  Future<void> handleMessage(ServerMessage message) async {
    if (message is ErrorResponseMessage) {
      _done.completeError(PostgreSQLException.fromFields(message.fields));
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
              StackTrace.current,
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
          _done.completeError(PostgreSQLException('Unhandled auth mechanism'));
      }
    } else if (message is ReadyForQueryMessage) {
      _done.complete();
    }
  }
}
