import 'package:postgres/src/messages/logical_replication_messages.dart';

/// Tracks and caches the type and name info of relations (tables, views,
/// indexes...).
///
/// Currently it only collects and caches [RelationMessage] instances.
///
/// The instance may be shared between connection pool instances.
///
/// TODO: Implement active querying using `pg_class` like the below query:
///       "SELECT relname FROM pg_class WHERE relkind='r' AND oid = ?",
///       https://www.postgresql.org/docs/current/catalog-pg-class.html
class DatabaseInfo {
  // Deliberately never evicted. PostgreSQL sends a RelationMessage once per
  // relation (or again if its schema changes) and expects the client to
  // remember it for the rest of the replication session - it will not
  // re-send one just because we forgot it. Evicting an entry here would mean
  // a later tuple for that relation silently falls back to undecoded bytes
  // (see TupleData._parse) instead of failing loudly, which is worse than
  // the unbounded growth. In practice this is bounded by the number of
  // distinct relations in the publication, which is normally small and
  // stable; for workloads with heavy schema churn (e.g. per-tenant tables or
  // partitioning), periodically restarting the replication session bounds
  // this the same way reconnecting bounds any other cache.
  final _relationMessages = <int, RelationMessage>{};

  /// Returns the type OID for [relationId] and [columnIndex].
  ///
  /// Returns `null` if the [relationId] is unknown or the [columnIndex]
  /// is out of bounds.
  Future<int?> getColumnTypeOidByRelationIdAndColumnIndex({
    required int relationId,
    required int columnIndex,
  }) async {
    if (columnIndex < 0) {
      throw ArgumentError('columnIndex must not be negative');
    }
    final m = _relationMessages[relationId];
    if (m == null) {
      return null;
    }
    if (columnIndex >= m.columns.length) {
      return null;
    }
    return m.columns[columnIndex].typeOid;
  }
}

extension DatabaseInfoExt on DatabaseInfo {
  void addRelationMessage(RelationMessage message) {
    _relationMessages[message.relationId] = message;
  }
}
