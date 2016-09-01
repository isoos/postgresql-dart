part of postgres;

class PostgreSQLFormatString {
  static int _AtSignCodeUnit = "@".codeUnitAt(0);

  static substitute(String fmtString, Map<String, dynamic> values) {
    var items = <PostgreSQLFormatStringToken>[];
    PostgreSQLFormatStringToken lastPtr = null;
    var iterator = new RuneIterator(fmtString);

    iterator.moveNext();
    while (iterator.current != null) {
      if (lastPtr == null) {
        if (iterator.current == _AtSignCodeUnit) {
          lastPtr = new PostgreSQLFormatStringToken(PostgreSQLFormatStringTokenType.marker);
          lastPtr.buffer.writeCharCode(iterator.current);
          items.add(lastPtr);
        } else {
          lastPtr = new PostgreSQLFormatStringToken(PostgreSQLFormatStringTokenType.text);
          lastPtr.buffer.writeCharCode(iterator.current);
          items.add(lastPtr);
        }
      } else if (lastPtr.type == PostgreSQLFormatStringTokenType.text) {
        if (iterator.current == _AtSignCodeUnit) {
          lastPtr = new PostgreSQLFormatStringToken(PostgreSQLFormatStringTokenType.marker);
          lastPtr.buffer.writeCharCode(iterator.current);
          items.add(lastPtr);
        } else {
          lastPtr.buffer.writeCharCode(iterator.current);
        }
      } else if (lastPtr.type == PostgreSQLFormatStringTokenType.marker) {
        if (iterator.current == _AtSignCodeUnit) {
          iterator.movePrevious();
          if (iterator.current == _AtSignCodeUnit) {
            lastPtr.buffer.writeCharCode(iterator.current);
            lastPtr.type = PostgreSQLFormatStringTokenType.text;
          } else {
            lastPtr = new PostgreSQLFormatStringToken(PostgreSQLFormatStringTokenType.marker);
            lastPtr.buffer.writeCharCode(iterator.current);
            items.add(lastPtr);
          }
          iterator.moveNext();

        } else if (isIdentifier(iterator.current)) {
          lastPtr.buffer.writeCharCode(iterator.current);
        } else {
          lastPtr = new PostgreSQLFormatStringToken(PostgreSQLFormatStringTokenType.text);
          lastPtr.buffer.writeCharCode(iterator.current);
          items.add(lastPtr);
        }
      }

      iterator.moveNext();
    }

    return items.map((t) {
      if (t.type == PostgreSQLFormatStringTokenType.text) {
        return t.buffer;
      } else {
        var key = t.buffer.toString();
        key = key.substring(1, key.length);

        if (!values.containsKey(key)) {
          throw new PostgreSQLFormatStringException("Format string specified identifier with name $key, but key was not present in values. Format string: $fmtString Values: $values");
        }

        return PostgreSQLCodec.encode(values[key]);
      }
    }).join("");
  }

  static int _lowercaseACodeUnit = "a".codeUnitAt(0);
  static int _uppercaseACodeUnit = "A".codeUnitAt(0);
  static int _lowercaseZCodeUnit = "z".codeUnitAt(0);
  static int _uppercaseZCodeUnit = "Z".codeUnitAt(0);
  static int _0CodeUnit = "0".codeUnitAt(0);
  static int _9CodeUnit= "9".codeUnitAt(0);
  static int _underscoreCodeUnit= "_".codeUnitAt(0);

  static bool isIdentifier(int charCode) {
    return (charCode >= _lowercaseACodeUnit && charCode <= _lowercaseZCodeUnit)
      || (charCode >= _uppercaseACodeUnit && charCode <= _uppercaseZCodeUnit)
      || (charCode >= _0CodeUnit && charCode <= _9CodeUnit)
      || (charCode == _underscoreCodeUnit);
  }
}


enum PostgreSQLFormatStringTokenType {
  text, marker
}

class PostgreSQLFormatStringToken {
  PostgreSQLFormatStringToken(this.type);

  PostgreSQLFormatStringTokenType type;
  StringBuffer buffer = new StringBuffer();
}

class PostgreSQLFormatStringException implements Exception {
  PostgreSQLFormatStringException(this.message);

  final String message;

  String toString() => message;
}