import 'dart:async';
import 'dart:collection';

import '../exceptions.dart';
import 'query.dart';

class QueryQueue extends ListBase<Query<dynamic>>
    implements List<Query<dynamic>> {
  List<Query<dynamic>> _inner = <Query<dynamic>>[];
  bool _isCancelled = false;

  PostgreSQLException get _cancellationException => PostgreSQLException(
      'Query cancelled due to the database connection closing.');

  Query<dynamic>? get pending {
    if (_inner.isEmpty) {
      return null;
    }
    return _inner.first;
  }

  void cancel([Object? error, StackTrace? stackTrace]) {
    _isCancelled = true;
    error ??= _cancellationException;
    final existing = _inner;
    _inner = <Query<dynamic>>[];

    // We need to jump this to the next event so that the queries
    // get the error and not the close message, since completeError is
    // synchronous.
    scheduleMicrotask(() {
      for (final q in existing) {
        q.completeError(error!, stackTrace);
      }
    });
  }

  @override
  set length(int newLength) {
    _inner.length = newLength;
  }

  @override
  Query operator [](int index) => _inner[index];

  @override
  int get length => _inner.length;

  @override
  void operator []=(int index, Query value) => _inner[index] = value;

  void addEvenIfCancelled(Query element) {
    _inner.add(element);
  }

  @override
  bool add(Query element) {
    if (_isCancelled) {
      // ignore: body_might_complete_normally_catch_error
      unawaited(element.future.catchError((_) {}));
      element.completeError(_cancellationException);
      return false;
    }

    _inner.add(element);
    return true;
  }

  @override
  void addAll(Iterable<Query> iterable) {
    _inner.addAll(iterable);
  }
}
