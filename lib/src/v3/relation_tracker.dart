import 'package:postgres/src/messages/logical_replication_messages.dart';

/// Trackes and caches the type and name info of relations (tables, views, indexes...).
///
/// Currently it only collects and caches [RelationMessage] instances.
///
/// TODO: Implement active querying using `pg_class` like the below query:
///       "SELECT relname FROM pg_class WHERE relkind='r' AND oid = ?",
///       https://www.postgresql.org/docs/current/catalog-pg-class.html
class RelationTracker {
  final _relationMessages = <int, RelationMessage>{};

  /// Returns the type OID for [relationId] and [columnIndex].
  /// Returns `null` if the [relationId] is unknown or the [columnIndex]
  /// is out of bounds.
  int? getTypeOid(int relationId, int columnIndex) {
    final m = _relationMessages[relationId];
    if (m == null) {
      return null;
    }
    if (columnIndex < 0 || columnIndex > m.columns.length) {
      return null;
    }
    return m.columns[columnIndex].typeOid;
  }
}

extension RelationInfoViewExt on RelationTracker {
  void addRelationMessage(RelationMessage message) {
    _relationMessages[message.relationId] = message;
  }
}
