import 'dart:convert';

import 'package:postgres/postgres.dart';

class PostgresTextEncoder {
  String convert(dynamic value, {bool escapeStrings = true}) {
    if (value == null) {
      return 'null';
    }

    if (value is int) {
      return _encodeNumber(value);
    }

    if (value is double) {
      return _encodeDouble(value);
    }

    if (value is String) {
      return _encodeString(value, escapeStrings);
    }

    if (value is DateTime) {
      return _encodeDateTime(value, isDateOnly: false);
    }

    if (value is bool) {
      return _encodeBoolean(value);
    }

    if (value is Map) {
      return _encodeJSON(value, escapeStrings);
    }

    if (value is PgPoint) {
      return _encodePoint(value);
    }

    if (value is List) {
      return _encodeList(value);
    }

    // TODO: use custom type encoders

    throw PostgreSQLException("Could not infer type of value '$value'.");
  }

  String _encodeString(String text, bool escapeStrings) {
    if (!escapeStrings) {
      return text;
    }

    final backslashCodeUnit = r'\'.codeUnitAt(0);
    final quoteCodeUnit = r"'".codeUnitAt(0);

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
      text.codeUnits.forEach((i) {
        if (i == quoteCodeUnit || i == backslashCodeUnit) {
          buf.writeCharCode(i);
          buf.writeCharCode(i);
        } else {
          buf.writeCharCode(i);
        }
      });
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

  String _encodePoint(PgPoint value) {
    return '(${_encodeDouble(value.latitude)}, ${_encodeDouble(value.longitude)})';
  }

  String _encodeList(List value) {
    if (value.isEmpty) {
      return '{}';
    }

    final type = value.fold(value.first.runtimeType, (type, item) {
      if (type == item.runtimeType) {
        return type;
      } else if ((type == int || type == double) && item is num) {
        return double;
      } else {
        return Map;
      }
    });

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

    throw PostgreSQLException("Could not infer array type of value '$value'.");
  }
}
