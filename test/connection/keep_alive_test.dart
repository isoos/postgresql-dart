import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:postgres/src/connection/keep_alive.dart';
import 'package:postgres/src/connection/resolved_settings.dart';
import 'package:test/test.dart';

void main() {
  final opts = KeepAliveOptions.current;

  group('settings resolution', () {
    test('enabled by default with OS timings', () {
      final s = ResolvedConnectionSettings(null, null).keepAlive;
      expect(s.enabled, isTrue);
      expect(s.idle, isNull);
      expect(s.interval, isNull);
      expect(s.count, isNull);
    });

    test('can be disabled', () {
      final s = ResolvedConnectionSettings(
        ConnectionSettings(keepAlive: KeepAliveSettings.disabled()),
        null,
      ).keepAlive;
      expect(s.enabled, isFalse);
    });

    test('fields are merged with the fallback', () {
      final s = ResolvedConnectionSettings(
        ConnectionSettings(keepAlive: KeepAliveSettings(count: 3)),
        ConnectionSettings(
          keepAlive: KeepAliveSettings(count: 9, idle: Duration(seconds: 30)),
        ),
      ).keepAlive;
      expect(s.enabled, isTrue);
      expect(s.idle, Duration(seconds: 30));
      expect(s.count, 3);
    });

    test('pool settings are forwarded to connection settings', () {
      final pool = ResolvedPoolSettings(
        PoolSettings(
          keepAlive: KeepAliveSettings(interval: Duration(seconds: 7)),
        ),
      );
      final conn = ResolvedConnectionSettings(null, pool);
      expect(conn.keepAlive.interval, Duration(seconds: 7));
      expect(conn.isMatchingConnection(pool), isTrue);
      expect(
        ResolvedConnectionSettings(
          ConnectionSettings(keepAlive: KeepAliveSettings.disabled()),
          pool,
        ).isMatchingConnection(pool),
        isFalse,
      );
    });

    test('rejects non-positive values', () {
      expect(
        () => ResolvedConnectionSettings(
          ConnectionSettings(keepAlive: KeepAliveSettings(idle: Duration.zero)),
          null,
        ),
        throwsArgumentError,
      );
      expect(
        () => ResolvedConnectionSettings(
          ConnectionSettings(keepAlive: KeepAliveSettings(count: 0)),
          null,
        ),
        throwsArgumentError,
      );
    });
  });

  group('socket options', () {
    late ServerSocket server;
    late Socket socket;

    setUp(() async {
      server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((c) => c.drain<void>().ignore());
      socket = await Socket.connect(server.address, server.port);
    });

    tearDown(() async {
      socket.destroy();
      await server.close();
    });

    int? read(int level, int option) => readRawIntOption(socket, level, option);

    test('applies the configured values', () {
      applyKeepAlive(
        socket,
        KeepAliveSettings(
          enabled: true,
          idle: Duration(seconds: 61),
          interval: Duration(milliseconds: 4500),
          count: 7,
        ),
      );
      expect(read(RawSocketOption.levelSocket, opts!.soKeepAlive), isNot(0));
      expect(read(RawSocketOption.levelTcp, opts.idle), 61);
      expect(read(RawSocketOption.levelTcp, opts.interval), 5);
      expect(read(RawSocketOption.levelTcp, opts.count), 7);
    });

    test('keeps OS timings when not specified', () {
      final idle = read(RawSocketOption.levelTcp, opts!.idle);
      final interval = read(RawSocketOption.levelTcp, opts.interval);
      final count = read(RawSocketOption.levelTcp, opts.count);
      applyKeepAlive(socket, KeepAliveSettings(enabled: true));
      expect(read(RawSocketOption.levelSocket, opts.soKeepAlive), isNot(0));
      expect(read(RawSocketOption.levelTcp, opts.idle), idle);
      expect(read(RawSocketOption.levelTcp, opts.interval), interval);
      expect(read(RawSocketOption.levelTcp, opts.count), count);
    });

    test('does nothing when disabled', () {
      applyKeepAlive(
        socket,
        KeepAliveSettings(enabled: false, idle: Duration(seconds: 61)),
      );
      expect(read(RawSocketOption.levelSocket, opts!.soKeepAlive), 0);
      expect(read(RawSocketOption.levelTcp, opts.idle), isNot(61));
    });
  }, skip: opts == null ? 'unsupported platform' : null);
}
