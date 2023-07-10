import 'package:postgres/postgres_v3_experimental.dart';


class InternalQueryDescription implements PgSql {
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
      // todo: Determine whether we want to use a direct SQL command by default.
      // Maybe this should be replaced with .map once implemented.
      return InternalQueryDescription.direct(query);
    } else if (query is InternalQueryDescription) {
      return query;
    } else {
      throw ArgumentError.value(query, 'query',
          'Must either be a String or an InternalQueryDescription');
    }
  }

  List<PgTypedParameter> bindParameters(Object? params) {
    final knownTypes = parameterTypes;

    if (params == null) {
      if (knownTypes != null && knownTypes.isNotEmpty) {
        throw ArgumentError.value(params, 'parameters',
            'This prepared statement has ${knownTypes.length} parameters that must be set.');
      }

      return const [];
    } else if (params is List) {
      if (knownTypes != null && knownTypes.length != params.length) {
        throw ArgumentError.value(params, 'parameters',
            'Expected ${knownTypes.length} parameters, got ${params.length}');
      }

      final parameters = <PgTypedParameter>[];
      for (var i = 0; i < params.length; i++) {
        final param = params[i];
        if (param is PgTypedParameter) {
          parameters.add(param);
        } else if (knownTypes != null) {
          parameters.add(PgTypedParameter(knownTypes[i], param));
        } else {
          throw ArgumentError.value(
            params,
            'parameters',
            'As no types have been set on this prepared statement, all '
                'parameters must be a `PgTypedParameter`.',
          );
        }
      }

      return parameters;
    } else if (params is Map) {
      throw UnimplementedError('todo: Support binding maps');
    } else {
      throw ArgumentError.value(
          params, 'parameters', 'Must either be a list or a map');
    }
  }
}
