import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('pool connect timeout leak', (server) {
    test(
      'a pool connect that times out does not leak the connection if it '
      'succeeds later',
      () async {
        // A proxy that delays before ever connecting to the real server, so
        // the pool's short connectTimeout fires first - but the real
        // connect (and the whole handshake) still succeeds shortly after,
        // in the background.
        final serverSocket = await ServerSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        addTearDown(serverSocket.close);

        final realSocketClosed = Completer<void>();
        serverSocket.listen((socket) async {
          await Future<void>.delayed(Duration(milliseconds: 400));
          final real = await Socket.connect(
            InternetAddress.loopbackIPv4,
            await server.port,
          );
          real.listen(
            socket.add,
            onDone: () {
              socket.destroy();
              if (!realSocketClosed.isCompleted) realSocketClosed.complete();
            },
            onError: (_) {
              socket.destroy();
              if (!realSocketClosed.isCompleted) realSocketClosed.complete();
            },
          );
          socket.listen(
            real.add,
            onDone: real.destroy,
            onError: (_) => real.destroy(),
          );
        });

        final endpoint = await server.endpoint();
        final pool = Pool.withEndpoints(
          [
            Endpoint(
              host: endpoint.host,
              port: serverSocket.port,
              database: endpoint.database,
              username: endpoint.username,
              password: endpoint.password,
            ),
          ],
          settings: PoolSettings(
            sslMode: SslMode.disable,
            // Bounds the pool's own connect-timeout wrapper.
            connectTimeout: Duration(milliseconds: 100),
          ),
        );
        addTearDown(() => pool.close(force: true));

        // The proxy doesn't even start connecting for 400ms, so the pool's
        // 100ms wrapper must time out well before the real connection is
        // established. The per-call `connectTimeout` override below only
        // bounds the individual connection's own internal handshake
        // timeout (kept generous, so that handshake genuinely succeeds
        // after the proxy's delay instead of separately timing out too -
        // isolating the pool-level bug this test targets).
        await expectLater(
          pool.withConnection(
            (c) => c.execute('SELECT 1'),
            settings: ConnectionSettings(connectTimeout: Duration(seconds: 5)),
          ),
          throwsA(anything),
        );

        // The real connection succeeds shortly after (around 400ms in) -
        // without the fix, it's never referenced again and stays open
        // forever; with the fix, it gets closed once connect() resolves.
        await realSocketClosed.future.timeout(Duration(seconds: 5));
      },
    );
  });
}
