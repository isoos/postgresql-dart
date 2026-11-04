import 'dart:io';
import 'dart:typed_data';

import '../../postgres.dart';

// Socket option numbers are not exposed by `dart:io` beyond the level, and
// differ by platform.
// - Linux/Android: <netinet/tcp.h>
// - macOS/iOS: <netinet/tcp.h>
// - Windows: <ws2ipdef.h>
const _soKeepAliveLinux = 9;
const _soKeepAliveOther = 8;

/// Applies [settings] to a connected, not yet TLS-wrapped [socket].
///
/// This is best-effort: if the platform rejects an option, it keeps its OS
/// default. Timings that are not set are left at the OS default.
void applyKeepAlive(Socket socket, KeepAliveSettings settings) {
  if (settings.enabled != true) {
    return;
  }
  final os = KeepAliveOptions.current;
  if (os == null) {
    return;
  }

  void setInt(int level, int option, int value) {
    try {
      socket.setRawOption(RawSocketOption.fromInt(level, option, value));
    } on Object {
      // Not supported on this platform or kernel: use the OS default.
    }
  }

  setInt(RawSocketOption.levelSocket, os.soKeepAlive, 1);

  final idle = settings.idle;
  if (idle != null) {
    setInt(RawSocketOption.levelTcp, os.idle, _seconds(idle));
  }
  final interval = settings.interval;
  if (interval != null) {
    setInt(RawSocketOption.levelTcp, os.interval, _seconds(interval));
  }
  final count = settings.count;
  if (count != null) {
    setInt(RawSocketOption.levelTcp, os.count, count);
  }
}

/// Reads back the integer value of a socket option, for tests.
int? readRawIntOption(Socket socket, int level, int option) {
  final raw = socket.getRawOption(RawSocketOption(level, option, Uint8List(4)));
  return ByteData.sublistView(raw).getInt32(0, Endian.host);
}

/// The raw option numbers used on the current platform.
class KeepAliveOptions {
  final int soKeepAlive;
  final int idle;
  final int interval;
  final int count;
  const KeepAliveOptions(
    this.soKeepAlive,
    this.idle,
    this.interval,
    this.count,
  );

  static final current = _detect();

  static KeepAliveOptions? _detect() {
    if (Platform.isLinux || Platform.isAndroid) {
      // TCP_KEEPIDLE, TCP_KEEPINTVL, TCP_KEEPCNT
      return const KeepAliveOptions(_soKeepAliveLinux, 4, 5, 6);
    }
    if (Platform.isMacOS || Platform.isIOS) {
      // TCP_KEEPALIVE (idle), TCP_KEEPINTVL, TCP_KEEPCNT
      return const KeepAliveOptions(_soKeepAliveOther, 0x10, 0x101, 0x102);
    }
    if (Platform.isWindows) {
      // TCP_KEEPIDLE, TCP_KEEPCNT, TCP_KEEPINTVL (Windows 10 1709+)
      return const KeepAliveOptions(_soKeepAliveOther, 3, 17, 16);
    }
    return null;
  }
}

/// Rounds up to whole seconds, as the kernel options have that resolution.
int _seconds(Duration d) => (d.inMilliseconds + 999) ~/ 1000;
