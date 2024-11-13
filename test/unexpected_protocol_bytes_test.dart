import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('unexpected protocol bytes', (server) {
    late Connection conn;
    late ServerSocket serverSocket;
    bool sendGarbageResponse = false;

    setUp(() async {
      serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      serverSocket.listen((socket) async {
        final clientSocket = await Socket.connect(
            InternetAddress.loopbackIPv4, await server.port);
        late StreamSubscription socketSubs;
        late StreamSubscription clientSubs;
        socketSubs = socket.listen(clientSocket.add, onDone: () {
          socketSubs.cancel();
          clientSubs.cancel();
          clientSocket.close();
        }, onError: (e) {
          socketSubs.cancel();
          clientSubs.cancel();
          clientSocket.close();
        });
        final pattern = [68, 0, 0, 0, 11, 0, 1, 0, 0, 0, 1];
        clientSubs = clientSocket.listen((data) {
          if (sendGarbageResponse) {
            final i = _bytesIndexOf(data, pattern);
            if (i >= 0) {
              data[i + pattern.length - 4] = 255;
              data[i + pattern.length - 3] = 255;
              data[i + pattern.length - 2] = 255;
              data[i + pattern.length - 1] = 250;
            }
            socket.add(data);
          } else {
            socket.add(data);
          }
        }, onDone: () {
          socketSubs.cancel();
          clientSubs.cancel();
          clientSocket.close();
        }, onError: (e) {
          socketSubs.cancel();
          clientSubs.cancel();
          clientSocket.close();
        });
      });

      final endpoint = await server.endpoint();
      conn = await Connection.open(
        Endpoint(
          host: endpoint.host,
          port: serverSocket.port,
          database: endpoint.database,
          password: endpoint.password,
          username: endpoint.username,
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable,
        ),
      );
    });

    tearDown(() async {
      await conn.close();
      await serverSocket.close();
    });

    test('inject bad bytes', () async {
      await conn.execute('SELECT 1;');
      sendGarbageResponse = true;
      await expectLater(
          () => conn.execute('SELECT 2;', queryMode: QueryMode.simple),
          throwsA(isA<PgException>()));
      expect(conn.isOpen, false);
    });
  });
}

int _bytesIndexOf(List<int> data, List<int> pattern) {
  for (var i = 0; i < data.length - pattern.length; i++) {
    var matches = true;
    for (var j = 0; j < pattern.length; j++) {
      if (data[i + j] != pattern[j]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return i;
    }
  }
  return -1;
}
