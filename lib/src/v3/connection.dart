import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:meta/meta.dart';
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:stream_channel/stream_channel.dart';

import '../auth/clear_text_authenticator.dart';
import '../auth/md5_authenticator.dart';
import '../charcodes.dart';
import '../connection.dart' show PostgreSQLException;
import 'protocol.dart';

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
    final channel = await _connect(settings);

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

  _PendingOperation? _pending;

  PgConnectionImplementation._(this._channel, this._settings) {
    _serverMessages = _channel.stream.listen(_handleMessage);
  }

  Future<void> _startup() {
    final result = _pending = _AuthenticationProcedure(this);
    _channel.sink.add(StartupMessage(
      _settings.endpoint.database,
      _settings.timeZone,
      username: _settings.username,
      // todo: Replication
    ));

    return result._done.future;
  }

  Future<void> _handleMessage(BaseMessage message) async {
    _serverMessages.pause();
    try {
      message as ServerMessage;

      if (_pending != null) {
        await _pending!.handleMessage(message);
      }
    } finally {
      _serverMessages.resume();
    }
  }

  @override
  PgChannels get channels => throw UnimplementedError();

  @override
  PgMessages get messages => throw UnimplementedError();

  @override
  Future<PgStatement> prepare(Object query, {Duration? timeout}) {
    throw UnimplementedError();
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

abstract class _PendingOperation {
  final PgConnectionImplementation connection;

  _PendingOperation(this.connection);

  @protected
  void finish() {
    assert(connection._pending == this);
    connection._pending = null;
  }

  Future<void> handleMessage(ServerMessage message);
}

class _AuthenticationProcedure extends _PendingOperation {
  final Completer<void> _done = Completer();

  _AuthenticationProcedure(super.connection) {
    _done.future.whenComplete(finish);
  }

  @override
  Future<void> handleMessage(ServerMessage message) async {
    if (message is ErrorResponseMessage) {
      _done.completeError(PostgreSQLException.fromFields(message.fields));
    } else if (message is AuthenticationMessage) {
      switch (message.type) {
        case AuthenticationMessage.KindOK:
          _done.complete();
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
    }
  }
}
