import '../../postgres.dart';
import '../v3/protocol.dart';
import '../v3/query_description.dart';

/// Merges inline SQL type annotations with runtime [TypedValue] types for use
/// in a [ParseMessage].
///
/// Inline annotations (from `:type` syntax) take precedence. For positions
/// without an annotation, the [TypedValue.type] is used as a hint so that
/// PostgreSQL can resolve polymorphic operators (e.g. `@>`, `&&`, `<@`).
List<int?>? _mergeTypeOids(
  List<Type?>? paramTypes,
  List<TypedValue>? fallbackTypes,
) {
  if (fallbackTypes == null || fallbackTypes.isEmpty) {
    return paramTypes?.map((e) => e?.oid).toList();
  }
  final length = paramTypes?.length ?? fallbackTypes.length;
  final result = <int?>[];
  for (var i = 0; i < length; i++) {
    final fromAnnotation = (paramTypes != null && i < paramTypes.length)
        ? paramTypes[i]?.oid
        : null;
    if (fromAnnotation != null) {
      result.add(fromAnnotation);
    } else {
      final type = i < fallbackTypes.length ? fallbackTypes[i].type : null;
      result.add((type != null && type != Type.unspecified) ? type.oid : null);
    }
  }
  return result;
}

/// Builds the [ParseMessage] for [description], merging the SQL-level type
/// annotations with [fallbackTypes] inferred from the bound [TypedValue]s.
ParseMessage buildParseMessage(
  InternalQueryDescription description,
  String statementName, [
  List<TypedValue>? fallbackTypes,
]) {
  return ParseMessage(
    description.transformedSql,
    statementName: statementName,
    typeOids: _mergeTypeOids(description.parameterTypes, fallbackTypes),
  );
}

/// Expands a transaction's `BEGIN` statement with the isolation level,
/// access mode and deferrable settings, if set.
extension TransactionSettingsBeginQuery on TransactionSettings {
  bool get shouldExpandBegin =>
      isolationLevel != null || accessMode != null || deferrable != null;

  void expandBegin(StringBuffer sb) {
    if (isolationLevel != null) {
      sb.write(isolationLevel!.queryPart);
    }
    if (accessMode != null) {
      sb.write(accessMode!.queryPart);
    }
    if (deferrable != null) {
      sb.write(deferrable!.queryPart);
    }
  }
}
