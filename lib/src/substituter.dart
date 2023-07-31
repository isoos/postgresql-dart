import 'query.dart';
import 'text_codec.dart';
import 'types.dart';

class PostgreSQLFormat {
  static final int _atSignCodeUnit = '@'.codeUnitAt(0);

  static String id(String name, {PostgreSQLDataType? type}) {
    if (type != null) {
      return '@$name:${dataTypeStringForDataType(type)}';
    }

    return '@$name';
  }

  static String? dataTypeStringForDataType(PostgreSQLDataType? dt) {
    return dt?.nameForSubstitution;
  }

  static String substitute(String fmtString, Map<String, dynamic>? values,
      {SQLReplaceIdentifierFunction? replace}) {
    final converter = PostgresTextEncoder();
    values ??= const {};
    replace ??= (spec, index) => converter.convert(values![spec.name]);

    final items = <PostgreSQLFormatToken>[];
    PostgreSQLFormatToken? currentPtr;
    final iterator = RuneIterator(fmtString);

    while (iterator.moveNext()) {
      if (currentPtr == null) {
        if (iterator.current == _atSignCodeUnit) {
          currentPtr =
              PostgreSQLFormatToken(PostgreSQLFormatTokenType.variable);
          currentPtr.buffer.writeCharCode(iterator.current);
          items.add(currentPtr);
        } else {
          currentPtr = PostgreSQLFormatToken(PostgreSQLFormatTokenType.text);
          currentPtr.buffer.writeCharCode(iterator.current);
          items.add(currentPtr);
        }
      } else if (currentPtr.type == PostgreSQLFormatTokenType.text) {
        if (iterator.current == _atSignCodeUnit) {
          currentPtr =
              PostgreSQLFormatToken(PostgreSQLFormatTokenType.variable);
          currentPtr.buffer.writeCharCode(iterator.current);
          items.add(currentPtr);
        } else {
          currentPtr.buffer.writeCharCode(iterator.current);
        }
      } else if (currentPtr.type == PostgreSQLFormatTokenType.variable) {
        if (iterator.current == _atSignCodeUnit) {
          iterator.movePrevious();
          if (iterator.current == _atSignCodeUnit) {
            currentPtr.buffer.writeCharCode(iterator.current);
            currentPtr.type = PostgreSQLFormatTokenType.text;
          } else {
            currentPtr =
                PostgreSQLFormatToken(PostgreSQLFormatTokenType.variable);
            currentPtr.buffer.writeCharCode(iterator.current);
            items.add(currentPtr);
          }
          iterator.moveNext();
        } else if (_isIdentifier(iterator.current)) {
          currentPtr.buffer.writeCharCode(iterator.current);
        } else {
          currentPtr = PostgreSQLFormatToken(PostgreSQLFormatTokenType.text);
          currentPtr.buffer.writeCharCode(iterator.current);
          items.add(currentPtr);
        }
      }
    }

    var idx = 1;
    return items.map((t) {
      if (t.type == PostgreSQLFormatTokenType.text) {
        return t.buffer;
      } else if (t.buffer.length == 1 && t.buffer.toString() == '@') {
        return t.buffer;
      } else {
        final identifier = PostgreSQLFormatIdentifier(t.buffer.toString());

        if (values != null && !values.containsKey(identifier.name)) {
          // Format string specified identifier with name ${identifier.name},
          // but key was not present in values.
          return t.buffer;
        }

        final val = replace!(identifier, idx);
        idx++;

        if (identifier.typeCast != null) {
          return '$val::${identifier.typeCast}';
        }

        return val;
      }
    }).join('');
  }

  static final int _lowercaseACodeUnit = 'a'.codeUnitAt(0);
  static final int _uppercaseACodeUnit = 'A'.codeUnitAt(0);
  static final int _lowercaseZCodeUnit = 'z'.codeUnitAt(0);
  static final int _uppercaseZCodeUnit = 'Z'.codeUnitAt(0);
  static final int _codeUnit0 = '0'.codeUnitAt(0);
  static final int _codeUnit9 = '9'.codeUnitAt(0);
  static final int _underscoreCodeUnit = '_'.codeUnitAt(0);
  static final int _colonCodeUnit = ':'.codeUnitAt(0);

  static bool _isIdentifier(int charCode) {
    return (charCode >= _lowercaseACodeUnit &&
            charCode <= _lowercaseZCodeUnit) ||
        (charCode >= _uppercaseACodeUnit && charCode <= _uppercaseZCodeUnit) ||
        (charCode >= _codeUnit0 && charCode <= _codeUnit9) ||
        (charCode == _underscoreCodeUnit) ||
        (charCode == _colonCodeUnit);
  }
}
