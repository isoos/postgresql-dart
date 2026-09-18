import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('SSL handshake timeout does not leak the raw socket', () async {
    final serverSocket = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final serverSideClosed = Completer<void>();
    serverSocket.listen((socket) {
      // Never respond to the client's SSLRequest, so the handshake times out.
      socket.listen(
        (_) {},
        onDone: serverSideClosed.complete,
        onError: (_) => serverSideClosed.complete(),
      );
    });
    addTearDown(serverSocket.close);

    await expectLater(
      Connection.open(
        Endpoint(
          host: 'localhost',
          port: serverSocket.port,
          database: 'dart_test',
          username: 'postgres',
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.require,
          connectTimeout: Duration(milliseconds: 200),
        ),
      ),
      throwsA(anything),
    );

    // If the client leaked the raw socket instead of destroying it on
    // handshake failure, the server side would never observe it closing.
    await serverSideClosed.future.timeout(Duration(seconds: 5));
  });
}
