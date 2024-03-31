import '../../postgres.dart';
import 'variable_tokenizer.dart';

class SqlImpl implements Sql {
  final String sql;
  final TokenizerMode mode;
  final String substitution;
  final List<Type>? types;

  SqlImpl.direct(this.sql, {this.types})
      : mode = TokenizerMode.none,
        substitution = '';

  SqlImpl.indexed(this.sql, {this.substitution = '@'})
      : mode = TokenizerMode.indexed,
        types = null;

  SqlImpl.named(this.sql, {this.substitution = '@'})
      : mode = TokenizerMode.named,
        types = null;
}

class InternalQueryDescription {
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
    Map<String, int>? namedVariables,
  ) : this._(
          transformed,
          original,
          parameterTypes,
          namedVariables,
        );

  factory InternalQueryDescription.indexed(
    String sql, {
    String substitution = '@',
    TypeRegistry? typeRegistry,
  }) {
    return _viaTokenizer(typeRegistry ?? TypeRegistry(), sql, substitution,
        TokenizerMode.indexed);
  }

  factory InternalQueryDescription.named(
    String sql, {
    String substitution = '@',
    TypeRegistry? typeRegistry,
  }) {
    return _viaTokenizer(
        typeRegistry ?? TypeRegistry(), sql, substitution, TokenizerMode.named);
  }

  static InternalQueryDescription _viaTokenizer(
    TypeRegistry typeRegistry,
    String sql,
    String substitution,
    TokenizerMode mode,
  ) {
    final charCodes = substitution.codeUnits;
    if (charCodes.length != 1) {
      throw ArgumentError.value(substitution, 'substitution',
          'Must be a string with a single code unit');
    }

    final tokenizer = VariableTokenizer(
      typeRegistry: typeRegistry,
      variableCodeUnit: charCodes[0],
      sql: sql,
      mode: mode,
    )..tokenize();

    return tokenizer.result;
  }

  factory InternalQueryDescription.wrap(
    Object query, {
    required TypeRegistry typeRegistry,
  }) {
    if (query is String) {
      return InternalQueryDescription.direct(query);
    } else if (query is InternalQueryDescription) {
      return query;
    } else if (query is SqlImpl) {
      switch (query.mode) {
        case TokenizerMode.none:
          return InternalQueryDescription.direct(
            query.sql,
            types: query.types,
          );
        case TokenizerMode.indexed:
          return InternalQueryDescription.indexed(
            query.sql,
            substitution: query.substitution,
            typeRegistry: typeRegistry,
          );
        case TokenizerMode.named:
          return InternalQueryDescription.named(
            query.sql,
            substitution: query.substitution,
            typeRegistry: typeRegistry,
          );
      }
    } else {
      throw ArgumentError.value(
          query, 'query', 'Must either be a String or an SqlImpl');
    }
  }

  TypedValue _toParameter(
    Object? value,
    Type? knownType, {
    String? name,
  }) {
    if (value is TypedValue) {
      if (value.type != Type.unspecified) {
        return value;
      }
      knownType = value.type;
      value = value.value;
    }
    if (knownType != null && knownType != Type.unspecified) {
      return TypedValue(knownType, value);
    } else if (value is TsVector) {
      return TypedValue(Type.tsvector, value);
    } else {
      return TypedValue(Type.unspecified, value);
    }
  }

  List<TypedValue> bindParameters(
    Object? params, {
    bool ignoreSuperfluous = false,
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

      if (unmatchedVariables.isNotEmpty && !ignoreSuperfluous) {
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
