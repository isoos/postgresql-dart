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
    if (columnIndex > m.columns.length) {
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
