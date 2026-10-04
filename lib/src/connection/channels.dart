import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

import '../../postgres.dart';
import '../v3/protocol.dart';

String _identifier(String source) {
  // To avoid complex ambiguity rules, we always wrap identifier in double
  // quotes. That means the only character we need to escape are double quotes
  // in the source.
  final escaped = source.replaceAll('"', '""');
  return '"$escaped"';
}

/// Implements [Channels] (`LISTEN`/`NOTIFY`) on top of a [Connection].
///
/// This only relies on the public [Connection] API (`execute`, `prepare`,
/// `isOpen`), so it has no access to - and no coupling with - connection-
/// internal state.
class ChannelsImplementation implements Channels {
  final Connection _connection;

  final _activeListeners = <String, List<MultiStreamController<String>>>{};
  final _all = StreamController<Notification>.broadcast();

  // We are using the pg_notify function in a prepared select statement to
  // efficiently implement [notify]. The future is cached so the statement is
  // only prepared once.
  Future<Statement>? _notifyStatement;

  ChannelsImplementation(this._connection);

  @override
  Stream<Notification> get all => _all.stream;

  @override
  Stream<String> operator [](String channel) {
    return Stream.multi((newListener) {
      newListener.onCancel = () => _unsubscribe(channel, newListener);

      final existingListeners = _activeListeners.putIfAbsent(channel, () => []);
      final needsSubscription = existingListeners.isEmpty;
      existingListeners.add(newListener);

      if (needsSubscription) {
        // Captured here, synchronously, because the LISTEN call below runs
        // in a deferred callback - by the time it can fail, the call stack
        // no longer contains whoever subscribed to this stream, so a stack
        // trace captured from within `_subscribe()` would only show internal
        // frames (see the equivalent comment on `connect()`).
        _subscribe(channel, newListener, Trace.current());
      }
    }, isBroadcast: true);
  }

  void _subscribe(
    String channel,
    MultiStreamController<String> firstListener,
    Trace callerTrace,
  ) {
    Future(() async {
      await _connection.execute(
        Sql('LISTEN ${_identifier(channel)}'),
        ignoreRows: true,
      );
    }).onError<Object>((error, stackTrace) {
      // Not just `firstListener`: later listeners that joined while this
      // LISTEN was in flight never got subscribed either - error out all
      // of them instead of leaving those hanging forever.
      final listeners =
          _activeListeners.remove(channel) ??
          <MultiStreamController<String>>[firstListener];
      final chain = Chain([Trace.from(stackTrace), callerTrace]);
      for (final listener in listeners) {
        listener
          ..addError(error, chain)
          ..close();
      }
    });
  }

  Future<void> _unsubscribe(
    String channel,
    MultiStreamController listener,
  ) async {
    // The entry may already be gone (a failed LISTEN or cancelAll() clears
    // it); nothing left to unsubscribe in that case.
    final listeners = _activeListeners[channel];
    if (listeners == null) {
      return;
    }
    listeners.remove(listener);

    if (listeners.isEmpty) {
      _activeListeners.remove(channel);

      // This runs as a `StreamSubscription.onCancel` callback, which can be
      // triggered by the connection closing while this listener is being
      // torn down - there is nothing to unlisten on a connection that's
      // already going away, so that race is not a real failure.
      if (!_connection.isOpen) {
        return;
      }
      try {
        await _connection.execute(
          Sql('UNLISTEN ${_identifier(channel)}'),
          ignoreRows: true,
        );
      } on PgException {
        if (_connection.isOpen) {
          rethrow;
        }
      }
    }
  }

  void deliverNotification(NotificationResponseMessage msg) {
    _all.add(
      Notification(
        processId: msg.processId,
        channel: msg.channel,
        payload: msg.payload,
      ),
    );
    final listeners = _activeListeners[msg.channel] ?? const [];

    for (final listener in listeners) {
      listener.add(msg.payload);
    }
  }

  @override
  Future<void> cancelAll() async {
    await _connection.execute(Sql('UNLISTEN *'));

    // Take a snapshot before closing: closing a listener does not trigger
    // its `onCancel` (that only fires when the consumer cancels), so we
    // clear the map ourselves instead of relying on `_unsubscribe`.
    final listeners = _activeListeners.values.toList();
    _activeListeners.clear();

    for (final entry in listeners) {
      for (final listener in entry) {
        await listener.close();
      }
    }
  }

  @override
  Future<void> notify(String channel, [String? payload]) async {
    final Statement statement;
    try {
      statement = await (_notifyStatement ??= _connection.prepare(
        Sql(r'SELECT pg_notify($1, $2)', types: [Type.text, Type.text]),
      ));
    } catch (_) {
      // Don't cache a failed prepare - a transient failure would otherwise
      // permanently break notify() on this connection.
      _notifyStatement = null;
      rethrow;
    }

    await statement.run([channel, payload]);
  }
}
