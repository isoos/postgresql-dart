import 'dart:async';

import 'package:pool/pool.dart';
import 'package:stack_trace/stack_trace.dart';

extension PackagePoolExt on Pool {
  Future<PoolResource> requestWithTimeout(Duration timeout) async {
    final stack = StackTrace.current;
    final completer = Completer<PoolResource>();

    // Timer handles Duration.zero (and negative durations) by firing on the
    // next tick - matching how Future.timeout()/Socket.connect() already
    // treat this same connectTimeout value elsewhere, instead of a silent
    // "wait forever".
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Failed to acquire pool lock.'),
          stack,
        );
      }
    });

    final resourceFuture = request();

    scheduleMicrotask(() {
      resourceFuture.then(
        (resource) async {
          timer.cancel();
          if (completer.isCompleted) {
            resource.release();
            return;
          }
          completer.complete(resource);
        },
        onError: (e, st) {
          timer.cancel();
          if (!completer.isCompleted) {
            completer.completeError(
              e,
              Chain([Trace.from(st), Trace.from(stack)]),
            );
          }
        },
      );
    });

    return completer.future;
  }

  Future<T> withRequestTimeout<T>(
    FutureOr<T> Function(Duration remainingTimeout) callback, {
    required Duration timeout,
  }) async {
    final sw = Stopwatch()..start();
    final resource = await requestWithTimeout(timeout);
    final remainingTimeout = timeout - sw.elapsed;
    try {
      return await callback(remainingTimeout);
    } finally {
      resource.release();
    }
  }
}
