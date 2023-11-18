import 'package:postgres/src/types/type_registry.dart';

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
    return dt == null ? null : TypeRegistry().lookupTypeName(dt);
  }
}
