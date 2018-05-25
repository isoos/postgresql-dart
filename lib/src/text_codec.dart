import 'dart:convert';

import 'package:postgres/postgres.dart';

class PostgresTextEncoder extends Converter<dynamic, String> {
  const PostgresTextEncoder(this.escapeStrings);

  final bool escapeStrings;

  @override
  String convert(dynamic value) {
    if (value == null) {
      return "null";
    }

    if (value is int) {
      return encodeNumber(value);
    }

    if (value is double) {
      return encodeDouble(value);
    }

    if (value is String) {
      return encodeString(value, escapeStrings);
    }

    if (value is DateTime) {
      return encodeDateTime(value, isDateOnly: false);
    }

    if (value is bool) {
      return encodeBoolean(value);
    }

    if (value is Map) {
      return encodeJSON(value);
    }

    throw new PostgreSQLException("Could not infer type of value '$value'.");
  }

  String encodeString(String text, bool escapeStrings) {
    if (!escapeStrings) {
      return text;
    }

    var backslashCodeUnit = r"\".codeUnitAt(0);
    var quoteCodeUnit = r"'".codeUnitAt(0);

    var quoteCount = 0;
    var backslashCount = 0;
    var it = new RuneIterator(text);
    while (it.moveNext()) {
      if (it.current == backslashCodeUnit) {
        backslashCount++;
      } else if (it.current == quoteCodeUnit) {
        quoteCount++;
      }
    }

    var buf = new StringBuffer();

    if (backslashCount > 0) {
      buf.write(" E");
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

  String encodeNumber(num value) {
    if (value.isNaN) {
      return "'nan'";
    }

    if (value.isInfinite) {
      return value.isNegative ? "'-infinity'" : "'infinity'";
    }

    return value.toInt().toString();
  }

  String encodeDouble(double value) {
    if (value.isNaN) {
      return "'nan'";
    }

    if (value.isInfinite) {
      return value.isNegative ? "'-infinity'" : "'infinity'";
    }

    return value.toString();
  }

  String encodeBoolean(bool value) {
    return value ? "TRUE" : "FALSE";
  }

  String encodeDateTime(DateTime value, {bool isDateOnly: false}) {
    var string = value.toIso8601String();

    if (isDateOnly) {
      string = string.split("T").first;
    } else {
      if (!value.isUtc) {
        var timezoneHourOffset = value.timeZoneOffset.inHours;
        var timezoneMinuteOffset = value.timeZoneOffset.inMinutes % 60;

        var hourComponent = timezoneHourOffset.abs().toString().padLeft(2, "0");
        var minuteComponent = timezoneMinuteOffset.abs().toString().padLeft(2, "0");

        if (timezoneHourOffset >= 0) {
          hourComponent = "+${hourComponent}";
        } else {
          hourComponent = "-${hourComponent}";
        }

        var timezoneString = [hourComponent, minuteComponent].join(":");
        string = [string, timezoneString].join("");
      }
    }

    if (string.substring(0, 1) == "-") {
      string = string.substring(1) + " BC";
    } else if (string.substring(0, 1) == "+") {
      string = string.substring(1);
    }

    return "'$string'";
  }

  String encodeJSON(dynamic value) {
    if (value == null) {
      return "null";
    }

    if (value is String) {
      return "'${json.encode(value)}'";
    }

    return "${json.encode(value)}";
  }
}
