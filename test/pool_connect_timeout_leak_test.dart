import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('pool connect timeout leak', (server) {
    // A proxy that delays before ever connecting to the real server, so a
    // short pool connectTimeout fires first - but the real connect (and the
    // whole handshake) still succeeds shortly after, in the background.
    // Returns the proxy's port and a completer that resolves once the real
    // (delayed) connection to Postgres is closed.
    Future<(int port, Completer<void> realSocketClosed)> startDelayingProxy(
      Duration delay,
    ) async {
      final serverSocket = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(serverSocket.close);

      final realSocketClosed = Completer<void>();
      serverSocket.listen((socket) async {
        await Future<void>.delayed(delay);
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

      return (serverSocket.port, realSocketClosed);
    }

    Future<Pool> openPool(int proxyPort) async {
      final endpoint = await server.endpoint();
      return Pool.withEndpoints(
        [
          Endpoint(
            host: endpoint.host,
            port: proxyPort,
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
    }

    test(
      'a pool connect that times out does not leak the connection if it '
      'succeeds later',
      () async {
        final (port, realSocketClosed) = await startDelayingProxy(
          Duration(milliseconds: 400),
        );
        final pool = await openPool(port);
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

    test(
      'Pool.close() waits for a timed-out connect that is still resolving',
      () async {
        // realSocketClosed isn't used directly here (its completion depends
        // on the *peer* observing a TCP close, which has its own network
        // propagation delay beyond what close() can control) - instead this
        // measures how long close() itself takes to return.
        final (port, _) = await startDelayingProxy(Duration(milliseconds: 400));
        final pool = await openPool(port);
        addTearDown(() => pool.close(force: true));

        final timeoutFired = Stopwatch()..start();
        await expectLater(
          pool.withConnection(
            (c) => c.execute('SELECT 1'),
            settings: ConnectionSettings(connectTimeout: Duration(seconds: 5)),
          ),
          throwsA(anything),
        );
        // The pool's ~100ms wrapper should have fired by now, well before
        // the proxy's 400ms delay elapses.
        expect(timeoutFired.elapsed, lessThan(Duration(milliseconds: 350)));

        // Without the fix, close() has nothing to wait for and returns
        // almost immediately; with the fix, it blocks until the straggler
        // connection above (which only resolves once the proxy's 400ms
        // delay elapses) has been closed - so the *total* time from the
        // timeout firing to close() returning must cover most of that
        // remaining delay.
        await pool.close();
        expect(
          timeoutFired.elapsed,
          greaterThan(Duration(milliseconds: 300)),
          reason: "close() returned too quickly - it isn't waiting for the "
              'still-resolving connect.',
        );
      },
    );
  });
}
