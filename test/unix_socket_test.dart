import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  if (Platform.isWindows) return;

  withPostgresServer('Unix socket transport', (server) {
    test(
      'Given a PostgreSQL connection through a Unix socket, '
      'when TLS and an extended transaction are used, '
      'then startup and portal cleanup preserve the encrypted connection.',
      () async {
        // Relay to the isolated container so this exercises a real Unix socket
        // without requiring a container socket mount on the host.
        final directory = await Directory.systemTemp.createTemp('pg-unix-');
        addTearDown(() => directory.delete(recursive: true));
        final path = '${directory.path}/postgres';
        final listener = await ServerSocket.bind(
          InternetAddress(path, type: InternetAddressType.unix),
          0,
        );
        addTearDown(listener.close);
        final sockets = <Socket>[];
        addTearDown(() {
          for (final socket in sockets) {
            socket.destroy();
          }
        });
        final port = await server.port;
        listener.listen((client) async {
          sockets.add(client);
          final backend = await Socket.connect('localhost', port);
          sockets.add(backend);
          client.listen(backend.add, onDone: backend.destroy);
          backend.listen(client.add, onDone: client.destroy);
        });

        final connection = await Connection.open(
          Endpoint(
            host: path,
            port: 0,
            database: 'postgres',
            username: 'postgres',
            password: 'postgres',
            isUnixSocket: true,
          ),
          settings: ConnectionSettings(sslMode: SslMode.require),
        );
        addTearDown(connection.close);
        final rows = await connection.runTx(
          (tx) => tx.execute(
            'SELECT ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid()',
          ),
        );
        final reused = await connection.execute('SELECT 42');

        expect(rows, [
          [true],
        ]);
        expect(reused, [
          [42],
        ]);
      },
    );
  });
}
