part of postgres;

typedef String SQLReplaceIdentifierFunction(PostgreSQLFormatIdentifier identifier, int index);

class PostgreSQLFormat {
  static int _AtSignCodeUnit = "@".codeUnitAt(0);
  static Map<String, int> _typeStringToCodeMap = {
    "text" : PostgreSQLCodec.TypeText,
    "int2" : PostgreSQLCodec.TypeInt2,
    "int4" : PostgreSQLCodec.TypeInt4,
    "int8" : PostgreSQLCodec.TypeInt8,
    "float4" : PostgreSQLCodec.TypeFloat4,
    "float8" : PostgreSQLCodec.TypeFloat8,
    "boolean" : PostgreSQLCodec.TypeBool,
    "date" : PostgreSQLCodec.TypeDate,
    "timestamp" : PostgreSQLCodec.TypeTimestamp,
    "timestamptz" : PostgreSQLCodec.TypeTimestampTZ
  };

  static String id(String name, {PostgreSQLDataType type: null}) {
    if (type != null) {
      return "@$name:${dataTypeStringForDataType(type)}";
    }

    return "@$name";
  }

  static String dataTypeStringForDataType(PostgreSQLDataType dt) {
    switch (dt) {
      case PostgreSQLDataType.text: return "text";
      case PostgreSQLDataType.integer: return "int4";
      case PostgreSQLDataType.smallInteger: return "int2";
      case PostgreSQLDataType.bigInteger: return "int8";
      case PostgreSQLDataType.serial: return "int4";
      case PostgreSQLDataType.bigSerial: return "int8";
      case PostgreSQLDataType.real: return "float4";
      case PostgreSQLDataType.double: return "float8";
      case PostgreSQLDataType.boolean: return "boolean";
      case PostgreSQLDataType.timestampWithoutTimezone: return "timestamp";
      case PostgreSQLDataType.timestampWithTimezone: return "timestamptz";
      case PostgreSQLDataType.date: return "date";
    }

    return null;
  }

  static int _postgresCodeForDataTypeString(String dt) {
    return _typeStringToCodeMap[dt];
  }

  static String substitute(String fmtString, Map<String, dynamic> values, {SQLReplaceIdentifierFunction replace: null}) {
    values ??= {};
    replace ??= (spec, index) => PostgreSQLCodec.encode(values[spec.name]);

    var items = <PostgreSQLFormatToken>[];
    PostgreSQLFormatToken lastPtr = null;
    var iterator = new RuneIterator(fmtString);

    iterator.moveNext();
    while (iterator.current != null) {
      if (lastPtr == null) {
        if (iterator.current == _AtSignCodeUnit) {
          lastPtr = new PostgreSQLFormatToken(PostgreSQLFormatTokenType.marker);
          lastPtr.buffer.writeCharCode(iterator.current);
          items.add(lastPtr);
        } else {
          lastPtr = new PostgreSQLFormatToken(PostgreSQLFormatTokenType.text);
          lastPtr.buffer.writeCharCode(iterator.current);
          items.add(lastPtr);
        }
      } else if (lastPtr.type == PostgreSQLFormatTokenType.text) {
        if (iterator.current == _AtSignCodeUnit) {
          lastPtr = new PostgreSQLFormatToken(PostgreSQLFormatTokenType.marker);
          lastPtr.buffer.writeCharCode(iterator.current);
          items.add(lastPtr);
        } else {
          lastPtr.buffer.writeCharCode(iterator.current);
        }
      } else if (lastPtr.type == PostgreSQLFormatTokenType.marker) {
        if (iterator.current == _AtSignCodeUnit) {
          iterator.movePrevious();
          if (iterator.current == _AtSignCodeUnit) {
            lastPtr.buffer.writeCharCode(iterator.current);
            lastPtr.type = PostgreSQLFormatTokenType.text;
          } else {
            lastPtr = new PostgreSQLFormatToken(PostgreSQLFormatTokenType.marker);
            lastPtr.buffer.writeCharCode(iterator.current);
            items.add(lastPtr);
          }
          iterator.moveNext();

        } else if (isIdentifier(iterator.current)) {
          lastPtr.buffer.writeCharCode(iterator.current);
        } else {
          lastPtr = new PostgreSQLFormatToken(PostgreSQLFormatTokenType.text);
          lastPtr.buffer.writeCharCode(iterator.current);
          items.add(lastPtr);
        }
      }

      iterator.moveNext();
    }

    var idx = 1;
    return items.map((t) {
      if (t.type == PostgreSQLFormatTokenType.text) {
        return t.buffer;
      } else {
        var identifier = new PostgreSQLFormatIdentifier(t.buffer.toString());

        if (!values.containsKey(identifier.name)) {
          throw new PostgreSQLFormatException("Format string specified identifier with name ${identifier.name}, but key was not present in values. Format string: $fmtString");
        }

        var val = replace(identifier, idx);
        idx ++;
        return val;
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
  static int _ColonCodeUnit = ":".codeUnitAt(0);

  static bool isIdentifier(int charCode) {
    return (charCode >= _lowercaseACodeUnit && charCode <= _lowercaseZCodeUnit)
        || (charCode >= _uppercaseACodeUnit && charCode <= _uppercaseZCodeUnit)
        || (charCode >= _0CodeUnit && charCode <= _9CodeUnit)
        || (charCode == _underscoreCodeUnit)
        || (charCode == _ColonCodeUnit);
  }
}


enum PostgreSQLFormatTokenType {
  text, marker
}

class PostgreSQLFormatToken {
  PostgreSQLFormatToken(this.type);

  PostgreSQLFormatTokenType type;
  StringBuffer buffer = new StringBuffer();
}

class PostgreSQLFormatIdentifier {
  PostgreSQLFormatIdentifier(String t) {
    var components = t.split(":");
    if (components.length == 1) {
      name = components.first;
    } else if (components.length == 2) {
      name = components.first;

      var dataTypeString = components.last;
      if (dataTypeString != null) {
        typeCode = PostgreSQLFormat._postgresCodeForDataTypeString(dataTypeString);
      }
    } else {
      throw new PostgreSQLFormatException("Invalid format string identifier, must contain identifier name and optionally one data type in format '@identifier:dataType' (offending identifier: ${t})");
    }

    // Strip @
    name = name.substring(1, name.length);
  }

  String name;
  int typeCode;
}

class PostgreSQLFormatException implements Exception {
  PostgreSQLFormatException(this.message);

  final String message;

  String toString() => message;
}