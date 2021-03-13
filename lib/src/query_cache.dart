import 'query.dart';

class QueryCache {
  final Map<String, CachedQuery> _queries = {};
  int _idCounter = 0;

  int get length => _queries.length;
  bool get isEmpty => _queries.isEmpty;

  void add(Query<dynamic> query) {
    if (query.cache == null) {
      return;
    }

    if (query.cache!.isValid) {
      _queries[query.statement] = query.cache!;
    }
  }

  CachedQuery? operator [](String? statementId) {
    if (statementId == null) {
      return null;
    }

    return _queries[statementId];
  }

  String identifierForQuery(Query<dynamic> query) {
    final existing = _queries[query.statement];
    if (existing != null) {
      return existing.preparedStatementName!;
    }

    final string = '$_idCounter'.padLeft(12, '0');

    _idCounter++;

    return string;
  }
}
