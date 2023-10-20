import '../../postgres.dart';
import 'variable_tokenizer.dart';

class InternalQueryDescription implements Sql {
  /// The SQL to send to postgres.
  ///
  /// This is the [originalSql] statement after local processing ran to
  /// substiute parameters.
  final String transformedSql;

  /// The SQL query as supplied by the user.
  final String originalSql;

  final List<Type?>? parameterTypes;
  final Map<String, int>? namedVariables;

  InternalQueryDescription._(
    this.transformedSql,
    this.originalSql,
    this.parameterTypes,
    this.namedVariables,
  );

  InternalQueryDescription.direct(String sql, {List<Type>? types})
      : this._(sql, sql, types, null);

  InternalQueryDescription.transformed(
    String original,
    String transformed,
    List<Type?> parameterTypes,
    Map<String, int> namedVariables,
  ) : this._(
          transformed,
          original,
          parameterTypes,
          namedVariables,
        );

  factory InternalQueryDescription.named(String sql,
      {String substitution = '@'}) {
    final charCodes = substitution.codeUnits;
    if (charCodes.length != 1) {
      throw ArgumentError.value(substitution, 'substitution',
          'Must be a string with a single code unit');
    }

    final tokenizer =
        VariableTokenizer(variableCodeUnit: charCodes[0], sql: sql)..tokenize();

    return tokenizer.result;
  }

  factory InternalQueryDescription.wrap(Object query) {
    if (query is String) {
      return InternalQueryDescription.direct(query);
    } else if (query is InternalQueryDescription) {
      return query;
    } else {
      throw ArgumentError.value(query, 'query',
          'Must either be a String or an InternalQueryDescription');
    }
  }

  TypedValue _toParameter(
    Object? value,
    Type? knownType, {
    String? name,
  }) {
    if (value is TypedValue) {
      return value;
    } else if (knownType != null) {
      return TypedValue(knownType, value);
    } else {
      return TypedValue(Type.unspecified, value);
    }
  }

  List<TypedValue> bindParameters(
    Object? params, {
    bool allowSuperfluous = false,
  }) {
    final knownTypes = parameterTypes;
    final parameters = <TypedValue>[];

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

      for (var i = 0; i < params.length; i++) {
        final param = params[i];
        final knownType = knownTypes != null ? knownTypes[i] : null;
        parameters.add(_toParameter(param, knownType, name: '[$i]'));
      }
    } else if (params is Map) {
      final byName = namedVariables;
      final unmatchedVariables = params.keys.toSet();
      if (byName == null) {
        throw ArgumentError.value(
            params, 'parameters', 'Maps are only supported by `Sql.named`');
      }

      var variableIndex = 1;
      for (final entry in byName.entries) {
        assert(entry.value == variableIndex);
        final type =
            knownTypes![variableIndex - 1]; // Known types are 0-indexed

        final name = entry.key;
        if (!params.containsKey(name)) {
          throw ArgumentError.value(
              params, 'parameters', 'Missing variable for `$name`');
        }

        final value = params[name];
        unmatchedVariables.remove(name);
        parameters.add(_toParameter(value, type, name: name));

        variableIndex++;
      }

      if (unmatchedVariables.isNotEmpty && !allowSuperfluous) {
        throw ArgumentError.value(params, 'parameters',
            'Contains superfluous variables: ${unmatchedVariables.join(', ')}');
      }
    } else {
      throw ArgumentError.value(
          params, 'parameters', 'Must either be a list or a map');
    }

    return parameters;
  }
}
