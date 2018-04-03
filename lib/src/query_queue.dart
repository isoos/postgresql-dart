import 'dart:async';
import 'dart:collection';

import 'package:postgres/postgres.dart';
import 'package:postgres/src/query.dart';

class QueryQueue extends ListBase<Query<dynamic>> implements List<Query<dynamic>> {
  List<Query<dynamic>> _inner = [];

  Query<dynamic> get pending {
    if (_inner.isEmpty) {
      return null;
    }
    return _inner.first;
  }

  void cancel([Object error, StackTrace stackTrace]) {
    error ??= "Cancelled";
    final existing = _inner;
    _inner = [];

    // We need to jump this to the next event so that the queries
    // get the error and not the close message, since completeError is
    // synchronous.
    scheduleMicrotask(() {
      var exception =
          new PostgreSQLException("Connection closed or query cancelled (reason: $error).", stackTrace: stackTrace);
      existing?.forEach((q) {
        q.completeError(exception, stackTrace);
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

  @override
  void add(Query element) {
    _inner.add(element);
  }

  @override
  void addAll(Iterable<Query> iterable) {
    _inner.addAll(iterable);
  }
}
