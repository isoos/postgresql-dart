import 'package:postgres/src/types/generic_type.dart';

import '../types.dart';

@Deprecated('Do not use v2 API, will be removed in next release.')
class PostgreSQLFormat {
  static String id(String name, {Type? type}) {
    if (type != null) {
      return '@$name:${dataTypeStringForDataType(type)}';
    }

    return '@$name';
  }

  static String? dataTypeStringForDataType(Type? dt) {
    final gt = dt is GenericType ? dt : null;
    return gt?.nameForSubstitution;
  }
}
