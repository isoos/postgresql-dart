import 'dart:async';
import 'dart:collection';

import 'package:postgres/postgres.dart';
import 'package:postgres/src/query.dart';

class QueryQueue extends ListBase<Query<dynamic>> implements List<Query<dynamic>> {
  List<Query<dynamic>> _inner = [];
  bool _isCancelled = false;

  PostgreSQLException get _cancellationException => new PostgreSQLException("Query cancelled due to the database connection closing.");

  Query<dynamic> get pending {
    if (_inner.isEmpty) {
      return null;
    }
    return _inner.first;
  }

  void cancel([dynamic error, StackTrace stackTrace]) {
    _isCancelled = true;
    error ??= _cancellationException;
    final existing = _inner;
    _inner = [];

    // We need to jump this to the next event so that the queries
    // get the error and not the close message, since completeError is
    // synchronous.
    scheduleMicrotask(() {
      existing?.forEach((q) {
        q.completeError(error, stackTrace);
      });
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
      element.future.catchError((_) {});
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
