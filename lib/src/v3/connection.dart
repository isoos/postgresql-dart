import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:buffer/buffer.dart';
import 'package:charcode/ascii.dart';
import 'package:collection/collection.dart';
import 'package:pool/pool.dart';
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:postgres/src/query.dart';
import 'package:stream_channel/stream_channel.dart';

import '../auth/clear_text_authenticator.dart';
import '../auth/md5_authenticator.dart';
import '../connection.dart' show PostgreSQLException;
import 'protocol.dart';
import 'query_description.dart';

const _debugLog = true;

class _ResolvedSettings {
  final PgEndpoint endpoint;
  final PgSessionSettings? settings;

  final String username;
  final String password;

  final Duration connectTimeout;
  final Duration queryTimeout;
  final String timeZone;
  final Encoding encoding;

  _ResolvedSettings(
    this.endpoint,
    this.settings,
  )   : username = endpoint.username ?? 'postgres',
        password = endpoint.password ?? 'postgres',
        connectTimeout =
            settings?.connectTimeout ?? const Duration(seconds: 15),
        queryTimeout = settings?.connectTimeout ?? const Duration(minutes: 5),
        timeZone = settings?.timeZone ?? 'UTC',
        encoding = settings?.encoding ?? utf8;

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
    subscription.pause();

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
      assert(subscription.isPaused);
      final controller = StreamController<Uint8List>(sync: true)
        ..onListen = subscription.resume
        ..onCancel = subscription.cancel
        ..onPause = subscription.pause
        ..onResume = subscription.resume;
      subscription
        ..onData(controller.add)
        ..onDone(controller.close)
        ..onError(controller.addError);

      adaptedStream = controller.stream;
    }

    return StreamChannel<List<int>>(adaptedStream, socket)
        .transform(messageTransformer);
  }

  final StreamChannel<BaseMessage> _channel;
  late final StreamSubscription<BaseMessage> _serverMessages;

  final _ResolvedSettings _settings;

  final Pool _operationLock = Pool(1);
  _PendingOperation? _pending;

  final Map<String, String> _parameters = {};
  int? _processId;
  int? _secretKey;

  var _statementCounter = 0;
  var _portalCounter = 0;

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
        _processId = message.processID;
        _secretKey = message.secretKey;
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
      _channel.sink.add(AggregatedClientMessage([send, SyncMessage()]));

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
  PgChannels get channels => throw UnimplementedError();

  @override
  PgMessages get messages => throw UnimplementedError();

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
      {Object? parameters, Duration? timeout}) {
    // TODO: implement execute
    throw UnimplementedError();
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
  Future<void> close() {
    throw UnimplementedError();
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
  final _BoundStatement _statement;
  final StreamController<PgResultRow> _controller;
  final StreamSubscription<PgResultRow> _source;

  final Completer<int> _affectedRows = Completer();

  final Completer<PgResultSchema> _schema = Completer();
  PgResultSchema? _resultSchema;

  late final _portalName = 'p/${connection._portalCounter++}';

  _PgResultStreamSubscription(this._statement, this._controller, this._source) {
    connection._operationLock.withResource(() async {
      connection._pending = this;

      connection._channel.sink.add(AggregatedClientMessage([
        BindMessage(
          [
            for (final parameter in _statement.parameters)
              ParameterValue.binary(parameter.value, parameter.type)
          ],
          portalName: _portalName,
          statementName: _statement.statement._name,
        ),
        DescribeMessage.portal(portalName: _portalName),
        ExecuteMessage(_portalName),
        SyncMessage(),
      ]));
    });
  }

  @override
  Future<int> get affectedRows => _affectedRows.future;

  @override
  Future<PgResultSchema> get schema => _schema.future;

  @override
  PgConnectionImplementation get connection => _statement.statement._connection;

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
          ),
      ]);
      _schema.complete(schema);
    } else if (message is DataRowMessage) {
      final schema = _resultSchema!;

      final row = _ResultRow(schema, [
        for (var i = 0; i < message.values.length; i++)
          schema.columns[i].type.codec.decode(message.values[i]),
      ]);

      _controller.add(row);
    } else if (message is CommandCompleteMessage) {
      _affectedRows.complete(message.rowsAffected);
    } else if (message is ReadyForQueryMessage) {
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

  _AuthenticationProcedure(super.connection);

  @override
  Future<void> handleMessage(ServerMessage message) async {
    if (message is ErrorResponseMessage) {
      _done.completeError(PostgreSQLException.fromFields(message.fields));
    } else if (message is AuthenticationMessage) {
      switch (message.type) {
        case AuthenticationMessage.KindOK:
          break;
        case AuthenticationMessage.KindMD5Password:
          // this means the server is requesting an md5 challenge
          // so the password must not be null
          final password = connection._settings.password;
          final user = connection._settings.username;

          final reader = ByteDataReader()..add(message.bytes);
          final salt = reader.read(4, copy: true);

          connection._channel.sink.add(AuthMD5Message(user, password, salt));
          break;
        case AuthenticationMessage.KindClearTextPassword:
          connection._channel.sink
              .add(ClearMessage(connection._settings.password));
          break;
        default:
          _done.completeError(PostgreSQLException('Unhandled auth mechanism'));
      }
    } else if (message is ReadyForQueryMessage) {
      _done.complete();
    }
  }
}
