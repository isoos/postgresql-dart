import 'package:postgres/postgres_v3_experimental.dart';

import 'types.dart';

class InternalQueryDescription implements PgQueryDescription {
  /// The SQL to send to postgres.
  ///
  /// This is the [originalSql] statement after local processing ran to
  /// substiute parameters.
  final String transformedSql;

  /// The SQL query as supplied by the user.
  final String originalSql;

  final List<PgDataType>? parameterTypes;

  InternalQueryDescription._(
      this.transformedSql, this.originalSql, this.parameterTypes);

  InternalQueryDescription.direct(String sql, {List<PgDataType>? types})
      : this._(sql, sql, types);

  factory InternalQueryDescription.map(String sql,
      {String substitution = '@'}) {
    // todo: Scan sql query, apply transformation
    throw UnimplementedError();
  }

  factory InternalQueryDescription.wrap(Object query) {
    if (query is String) {
      return InternalQueryDescription.map(query);
    } else if (query is InternalQueryDescription) {
      return query;
    } else {
      throw ArgumentError.value(query, 'query',
          'Must either be a String or an InternalQueryDescription');
    }
  }
}
