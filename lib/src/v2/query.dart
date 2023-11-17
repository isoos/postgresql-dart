import 'package:postgres/src/types/type_registry.dart';

import '../types.dart';

@Deprecated('Do not use v2 API, will be removed in next release.')
class ParameterValue extends TypedValue {
  ParameterValue(Type? type, Object? value)
      : super(type ?? Type.unspecified, value);
}

@Deprecated('Do not use v2 API, will be removed in next release.')
typedef SQLReplaceIdentifierFunction = String Function(
    PostgreSQLFormatIdentifier identifier, int index);

@Deprecated('Do not use v2 API, will be removed in next release.')
enum PostgreSQLFormatTokenType { text, variable }

@Deprecated('Do not use v2 API, will be removed in next release.')
class PostgreSQLFormatToken {
  PostgreSQLFormatToken(this.type);

  PostgreSQLFormatTokenType type;
  StringBuffer buffer = StringBuffer();
}

@Deprecated('Do not use v2 API, will be removed in next release.')
class PostgreSQLFormatIdentifier {
  static final typeStringToCodeMap = TypeRegistry();

  factory PostgreSQLFormatIdentifier(String t) {
    String name;
    Type? type;
    String? typeCast;

    final components = t.split('::');
    if (components.length > 1) {
      typeCast = components.sublist(1).join('');
    }

    final variableComponents = components.first.split(':');
    if (variableComponents.length == 1) {
      name = variableComponents.first;
    } else if (variableComponents.length == 2) {
      name = variableComponents.first;

      final dataTypeString = variableComponents.last;
      type = typeStringToCodeMap.resolveSubstitution(dataTypeString);
      if (type == null) {
        throw FormatException(
            "Invalid type code in substitution variable '$t'");
      }
    } else {
      throw FormatException(
          "Invalid format string identifier, must contain identifier name and optionally one data type in format '@identifier:dataType' (offending identifier: $t)");
    }

    // Strip @
    name = name.substring(1, name.length);
    return PostgreSQLFormatIdentifier._(name, type, typeCast);
  }

  PostgreSQLFormatIdentifier._(this.name, this.type, this.typeCast);

  final String name;
  final Type? type;
  final String? typeCast;
}
