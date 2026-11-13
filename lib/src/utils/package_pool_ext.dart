import 'dart:async';

import 'package:pool/pool.dart';
import 'package:stack_trace/stack_trace.dart';

extension PackagePoolExt on Pool {
  Future<PoolResource> requestWithTimeout(Duration timeout) async {
    final completer = Completer<PoolResource>();

    // Timer handles Duration.zero (and negative durations) by firing on the
    // next tick - matching how Future.timeout()/Socket.connect() already
    // treat this same connectTimeout value elsewhere, instead of a silent
    // "wait forever".
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(const _AcquireTimedOut());
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
            completer.completeError(e, st);
          }
        },
      );
    });

    // Errors are rethrown here, in the function the caller awaits, so that
    // their stack trace is the caller's awaiter chain. Capturing that up
    // front instead cost a StackTrace.current on every acquire, which was a
    // large part of the cost of a pooled query.
    try {
      return await completer.future;
    } on _AcquireTimedOut {
      throw TimeoutException('Failed to acquire pool lock.');
    } catch (e, st) {
      Error.throwWithStackTrace(e, Chain([Trace.from(st), Trace.current()]));
    }
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

/// Completes a pool request whose wait timed out; replaced with a
/// [TimeoutException] in [PackagePoolExt.requestWithTimeout].
class _AcquireTimedOut {
  const _AcquireTimedOut();
}
