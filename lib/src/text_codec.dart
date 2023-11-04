import 'dart:convert';
import 'dart:typed_data';

import 'exceptions.dart';
import 'types.dart';

class PostgresTextEncoder {
  const PostgresTextEncoder();

  String convert(dynamic input, {bool escapeStrings = true}) {
    if (input == null) {
      return 'null';
    }

    if (input is int) {
      return _encodeNumber(input);
    }

    if (input is double) {
      return _encodeDouble(input);
    }

    if (input is String) {
      return _encodeString(input, escapeStrings);
    }

    if (input is DateTime) {
      return _encodeDateTime(input, isDateOnly: false);
    }

    if (input is bool) {
      return _encodeBoolean(input);
    }

    if (input is Map) {
      return _encodeJSON(input, escapeStrings);
    }

    if (input is Point) {
      return _encodePoint(input);
    }

    if (input is List) {
      return _encodeList(input);
    }

    // TODO: use custom type encoders

    throw PgException("Could not infer type of value '$input'.");
  }

  String _encodeString(String text, bool escapeStrings) {
    if (!escapeStrings) {
      return text;
    }

    final backslashCodeUnit = r'\'.codeUnitAt(0);
    final quoteCodeUnit = "'".codeUnitAt(0);

    var quoteCount = 0;
    var backslashCount = 0;
    final it = RuneIterator(text);
    while (it.moveNext()) {
      if (it.current == backslashCodeUnit) {
        backslashCount++;
      } else if (it.current == quoteCodeUnit) {
        quoteCount++;
      }
    }

    final buf = StringBuffer();

    if (backslashCount > 0) {
      buf.write(' E');
    }

    buf.write("'");

    if (quoteCount == 0 && backslashCount == 0) {
      buf.write(text);
    } else {
      for (final i in text.codeUnits) {
        if (i == quoteCodeUnit || i == backslashCodeUnit) {
          buf.writeCharCode(i);
          buf.writeCharCode(i);
        } else {
          buf.writeCharCode(i);
        }
      }
    }

    buf.write("'");

    return buf.toString();
  }

  String _encodeNumber(num value) {
    if (value.isNaN) {
      return "'nan'";
    }

    if (value.isInfinite) {
      return value.isNegative ? "'-infinity'" : "'infinity'";
    }

    return value.toInt().toString();
  }

  String _encodeDouble(double value) {
    if (value.isNaN) {
      return "'nan'";
    }

    if (value.isInfinite) {
      return value.isNegative ? "'-infinity'" : "'infinity'";
    }

    return value.toString();
  }

  String _encodeBoolean(bool value) {
    return value ? 'TRUE' : 'FALSE';
  }

  String _encodeDateTime(DateTime value, {bool isDateOnly = false}) {
    var string = value.toIso8601String();

    if (isDateOnly) {
      string = string.split('T').first;
    } else {
      if (!value.isUtc) {
        final timezoneHourOffset = value.timeZoneOffset.inHours;
        final timezoneMinuteOffset = value.timeZoneOffset.inMinutes % 60;

        var hourComponent = timezoneHourOffset.abs().toString().padLeft(2, '0');
        final minuteComponent =
            timezoneMinuteOffset.abs().toString().padLeft(2, '0');

        if (timezoneHourOffset >= 0) {
          hourComponent = '+$hourComponent';
        } else {
          hourComponent = '-$hourComponent';
        }

        final timezoneString = [hourComponent, minuteComponent].join(':');
        string = [string, timezoneString].join('');
      }
    }

    if (string.substring(0, 1) == '-') {
      string = '${string.substring(1)} BC';
    } else if (string.substring(0, 1) == '+') {
      string = string.substring(1);
    }

    return "'$string'";
  }

  String _encodeJSON(dynamic value, bool escapeStrings) {
    if (value == null) {
      return 'null';
    }

    if (value is String) {
      return "'${json.encode(value)}'";
    }

    return _encodeString(json.encode(value), escapeStrings);
  }

  String _encodePoint(Point value) {
    return '(${_encodeDouble(value.latitude)}, ${_encodeDouble(value.longitude)})';
  }

  String _encodeList(List value) {
    if (value.isEmpty) {
      return '{}';
    }

    final first = value.first as Object?;
    final type = value.fold(first.runtimeType, (type, item) {
      if (type == item.runtimeType) {
        return type;
      } else if ((type == int || type == double) && item is num) {
        return double;
      } else {
        return Map;
      }
    });

    if (type == bool) {
      return '{${value.cast<bool>().map((s) => s.toString()).join(',')}}';
    }

    if (type == int || type == double) {
      return '{${value.cast<num>().map((s) => s is double ? _encodeDouble(s) : _encodeNumber(s)).join(',')}}';
    }

    if (type == String) {
      return '{${value.cast<String>().map((s) {
        final escaped = s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
        return '"$escaped"';
      }).join(',')}}';
    }

    if (type == Map) {
      return '{${value.map((s) {
        final escaped =
            json.encode(s).replaceAll(r'\', r'\\').replaceAll('"', r'\"');

        return '"$escaped"';
      }).join(',')}}';
    }

    throw PgException("Could not infer array type of value '$value'.");
  }
}

class PostgresTextDecoder {
  final int _typeOid;
  final Type _type;

  const PostgresTextDecoder(this._typeOid, this._type);

  Object? convert(Uint8List? input, Encoding encoding) {
    if (input == null) return null;

    late final asText = encoding.decode(input);

    // ignore: unnecessary_cast
    switch (_type as Type<Object>) {
      case Type.name:
      case Type.text:
      case Type.varChar:
        return asText;
      case Type.integer:
      case Type.smallInteger:
      case Type.bigInteger:
      case Type.serial:
      case Type.bigSerial:
        return int.parse(asText);
      case Type.real:
      case Type.double:
        return num.parse(asText);
      case Type.boolean:
        // In text data format when using simple query protocol, "true" & "false"
        // are represented as `t` and `f`,  respectively.
        // we will check for both just in case
        // TODO: should we check for other representations (e.g. `1`, `on`, `y`,
        // and `yes`)?
        return asText == 't' || asText == 'true';

      case Type.voidType:
        // TODO: is returning `null` here is the appripriate thing to do?
        return null;

      case Type.timestampWithTimezone:
      case Type.timestampWithoutTimezone:
      case Type.interval:
      case Type.numeric:
      case Type.byteArray:
      case Type.date:
      case Type.json:
      case Type.jsonb:
      case Type.uuid:
      case Type.point:
      case Type.booleanArray:
      case Type.integerArray:
      case Type.bigIntegerArray:
      case Type.textArray:
      case Type.doubleArray:
      case Type.varCharArray:
      case Type.jsonbArray:
      case Type.regtype:
        // TODO: implement proper decoding of the above
        return TypedBytes(typeOid: _typeOid, bytes: input);
      case Type.unspecified:
      case Type.unknownType:
        return TypedBytes(typeOid: _typeOid, bytes: input);
    }
  }
}
