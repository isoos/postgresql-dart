import 'package:postgres/src/query.dart';

class QueryCache {
  final Map<String, CachedQuery> queries = {};
  int idCounter = 0;

  void add(Query<dynamic> query) {
    if (query.cache == null) {
      return;
    }

    if (query.cache.isValid) {
      queries[query.statement] = query.cache;
    }
  }

  operator [](String statementId) {
    if (statementId == null) {
      return null;
    }

    return queries[statementId];
  }

  String identifierForQuery(Query<dynamic> query) {
    var existing = queries[query.statement];
    if (existing != null) {
      return existing.preparedStatementName;
    }

    var string = "$idCounter".padLeft(12, "0");

    idCounter++;

    return string;
  }
}