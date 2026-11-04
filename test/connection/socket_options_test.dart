import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Given a real TCP socket, '
    'when PostgreSQL receives SSLRequest, '
    'then the client kernel has TCP_NODELAY enabled before TLS upgrade.',
    () async {
      final listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(listener.close);
      late Socket client;
      final noDelay = Completer<int>();
      final peerClosed = Completer<void>();
      listener.listen((peer) {
        addTearDown(peer.destroy);
        final request = <int>[];
        peer.listen((bytes) {
          request.addAll(bytes);
          if (request.length == 8) {
            // TCP_NODELAY is option 1 at IPPROTO_TCP on Linux.
            final value = client.getRawOption(
              RawSocketOption.fromInt(RawSocketOption.levelTcp, 1, 0),
            );
            noDelay.complete(
              ByteData.sublistView(value).getInt32(0, Endian.host),
            );
            peer.add([78]); // Refuse TLS after inspecting the raw socket.
          }
        }, onDone: peerClosed.complete);
      });

      await expectLater(
        IOOverrides.runZoned(
          () => Connection.open(
            Endpoint(
              host: '127.0.0.1',
              port: listener.port,
              database: 'postgres',
            ),
            settings: ConnectionSettings(sslMode: SslMode.require),
          ),
          socketConnect:
              (host, port, {sourceAddress, sourcePort = 0, timeout}) async {
                final task = await Socket.startConnect(host, port);
                return client = await task.socket;
              },
        ),
        throwsA(isA<PgException>()),
      );
      final option = await noDelay.future;
      await peerClosed.future.timeout(Duration(seconds: 5));

      expect(option, 1);
    },
    skip: !Platform.isLinux ? 'Linux getsockopt option layout' : false,
  );

  test('Given a TCP connection, '
      'when opening it without TLS, '
      'then TCP_NODELAY is enabled before startup.', () async {
    final socket = _StartupSocket();

    final connection = await socket.open();
    addTearDown(connection.close);

    expect(socket.events, ['tcpNoDelay=true', 'startup']);
    expect(connection.isOpen, isTrue);
  });

  test(
    'Given a TCP connection requiring TLS, '
    'when the server refuses TLS, '
    'then TCP_NODELAY precedes SSLRequest and the socket is destroyed.',
    () async {
      final socket = _StartupSocket();

      await expectLater(
        socket.open(sslMode: SslMode.require),
        throwsA(isA<PgException>()),
      );

      expect(socket.events, ['tcpNoDelay=true', 'sslRequest', 'destroy']);
    },
  );

  test('Given a socket that returns false for TCP_NODELAY, '
      'when opening the connection, '
      'then the optional optimization does not prevent startup.', () async {
    final socket = _StartupSocket(setOptionResult: false);

    final connection = await socket.open();
    addTearDown(connection.close);

    expect(socket.events, ['tcpNoDelay=true', 'startup']);
    expect(connection.isOpen, isTrue);
  });

  test('Given a socket that throws UnsupportedError for TCP_NODELAY, '
      'when opening the connection, '
      'then the optional optimization does not prevent startup.', () async {
    final socket = _StartupSocket(optionError: UnsupportedError('option'));

    final connection = await socket.open();
    addTearDown(connection.close);

    expect(socket.events, ['tcpNoDelay=true', 'startup']);
    expect(connection.isOpen, isTrue);
  });

  test(
    'Given a socket that fails while setting TCP_NODELAY, '
    'when opening the connection, '
    'then the original error is reported and the socket is destroyed.',
    () async {
      final error = SocketException('socket closed');
      final socket = _StartupSocket(optionError: error);

      await expectLater(socket.open(), throwsA(same(error)));

      expect(socket.events, ['tcpNoDelay=true', 'destroy']);
    },
  );

  test('Given a Unix socket connection, '
      'when opening it, '
      'then startup succeeds without setting a TCP option.', () async {
    final socket = _StartupSocket();

    final connection = await socket.open(isUnixSocket: true);
    addTearDown(connection.close);

    expect(socket.events, ['startup']);
    expect(socket.connectedAddress.type, InternetAddressType.unix);
    expect(connection.isOpen, isTrue);
  });
}

// A controllable transport is needed to exercise unsupported options and socket
// failures, which cannot be induced portably on the host's real TCP sockets.
// It only implements startup; query and TLS behavior use real-server tests.
class _StartupSocket implements Socket {
  final bool setOptionResult;
  final Object? optionError;
  final events = <String>[];
  final _incoming = StreamController<Uint8List>();
  final _closed = Completer<void>();
  late InternetAddress connectedAddress;

  _StartupSocket({this.setOptionResult = true, this.optionError});

  Future<Connection> open({
    SslMode sslMode = SslMode.disable,
    bool isUnixSocket = false,
  }) => IOOverrides.runZoned(
    () => Connection.open(
      Endpoint(
        host: isUnixSocket ? '/tmp/postgres-test.sock' : 'localhost',
        database: 'postgres',
        username: 'postgres',
        isUnixSocket: isUnixSocket,
      ),
      settings: ConnectionSettings(sslMode: sslMode),
    ),
    socketConnect:
        (host, port, {sourceAddress, sourcePort = 0, timeout}) async {
          connectedAddress = host is InternetAddress
              ? host
              : InternetAddress.loopbackIPv4;
          return this;
        },
  );

  @override
  bool setOption(SocketOption option, bool enabled) {
    expect(option, SocketOption.tcpNoDelay);
    events.add('tcpNoDelay=$enabled');
    if (optionError case final error?) {
      // Tests deliberately supply both Error and Exception implementations.
      // ignore: only_throw_errors
      throw error;
    }
    return setOptionResult;
  }

  @override
  void add(List<int> data) {
    if (data.length == 8 && data[7] == 47) {
      events.add('sslRequest');
      _incoming.add(Uint8List.fromList([78])); // SSL not supported.
    } else if (data[0] == 0) {
      events.add('startup');
      _incoming.add(
        Uint8List.fromList([
          82, 0, 0, 0, 8, 0, 0, 0, 0, // AuthenticationOk.
          90, 0, 0, 0, 5, 73, // ReadyForQuery, idle.
        ]),
      );
    }
  }

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _incoming.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  void destroy() {
    if (!_closed.isCompleted) {
      events.add('destroy');
      unawaited(_incoming.close());
      _closed.complete();
    }
  }

  @override
  Future<void> close() async => destroy();

  @override
  Future<void> get done => _closed.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
