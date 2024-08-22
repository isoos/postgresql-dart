import 'dart:convert';
import 'dart:typed_data';

import 'package:postgres/src/types/generic_type.dart';

import '../exceptions.dart';
import '../types.dart';
import 'geo_types.dart';
import 'type_registry.dart';

class PostgresTextEncoder {
  const PostgresTextEncoder();

  String convert(Object? input, {bool escapeStrings = true}) {
    final value = tryConvert(input, escapeStrings: escapeStrings);
    if (value != null) {
      return value;
    }
    throw PgException("Could not infer type of value '$input'.");
  }

  String? tryConvert(Object? input, {bool escapeStrings = false}) {
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

    return null;
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
  static Object? convert(TypeCodecContext context, int typeOid, Uint8List di) {
    String asText() => context.encoding.decode(di);
    // ignore: unnecessary_cast
    switch (typeOid) {
      case TypeOid.character:
      case TypeOid.name:
      case TypeOid.text:
      case TypeOid.varChar:
        return asText();
      case TypeOid.integer:
      case TypeOid.smallInteger:
      case TypeOid.bigInteger:
        return int.parse(asText());
      case TypeOid.real:
      case TypeOid.double:
        return double.parse(asText());
      case TypeOid.boolean:
        // In text data format when using simple query protocol, "true" & "false"
        // are represented as `t` and `f`,  respectively.
        // we will check for both just in case
        // TODO: should we check for other representations (e.g. `1`, `on`, `y`,
        // and `yes`)?
        final t = asText();
        return t == 't' || t == 'true';

      case TypeOid.voidType:
        // TODO: is returning `null` here is the appripriate thing to do?
        return null;

      case TypeOid.timestampWithTimezone:
      case TypeOid.timestampWithoutTimezone:
        final raw = DateTime.parse(asText());
        return DateTime.utc(
          raw.year,
          raw.month,
          raw.day,
          raw.hour,
          raw.minute,
          raw.second,
          raw.millisecond,
          raw.microsecond,
        );

      case TypeOid.numeric:
        return asText();

      case TypeOid.date:
        final raw = DateTime.parse(asText());
        return DateTime.utc(raw.year, raw.month, raw.day);

      case TypeOid.json:
      case TypeOid.jsonb:
        return jsonDecode(asText());

      case TypeOid.interval:
      case TypeOid.byteArray:
      case TypeOid.uuid:
      case TypeOid.point:
      case TypeOid.booleanArray:
      case TypeOid.integerArray:
      case TypeOid.bigIntegerArray:
      case TypeOid.textArray:
      case TypeOid.doubleArray:
      case TypeOid.varCharArray:
      case TypeOid.jsonbArray:
      case TypeOid.regtype:
        // TODO: implement proper decoding of the above
        return UndecodedBytes(
          typeOid: typeOid,
          bytes: di,
          isBinary: false,
          encoding: context.encoding,
        );
    }
    return UndecodedBytes(
      typeOid: typeOid,
      bytes: di,
      isBinary: false,
      encoding: context.encoding,
    );
  }
}
