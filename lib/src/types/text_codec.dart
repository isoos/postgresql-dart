import 'dart:convert';
import 'dart:typed_data';

import '../exceptions.dart';
import '../types.dart';
import 'codec.dart';
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

    if (input is Uint8List) {
      return _encodeBytea(input, escapeStrings);
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
        // On some platforms, toIso8601String() for a local DateTime already
        // includes a timezone suffix (e.g. '+0200'). Strip it so we don't
        // produce a double suffix like '...+0200+02:00'.
        final tIdx = string.indexOf('T');
        if (tIdx != -1) {
          // Search for a timezone sign after the time-of-day part. Skip the
          // first character after 'T' to avoid mistaking a leading '-' in a
          // negative year for a timezone sign.
          final timepart = string.substring(tIdx + 1);
          final plusIdx = timepart.indexOf('+');
          // A '-' that is part of the time zone must appear after at least
          // 'HH:MM' (5 chars), so require index > 4.
          final minusIdx = timepart.lastIndexOf('-');
          final tzStart = plusIdx != -1
              ? plusIdx
              : (minusIdx > 4 ? minusIdx : -1);
          if (tzStart != -1) {
            string = string.substring(0, tIdx + 1 + tzStart);
          }
        }

        final timezoneHourOffset = value.timeZoneOffset.inHours;
        final timezoneMinuteOffset = value.timeZoneOffset.inMinutes % 60;

        var hourComponent = timezoneHourOffset.abs().toString().padLeft(2, '0');
        final minuteComponent = timezoneMinuteOffset.abs().toString().padLeft(
          2,
          '0',
        );

        if (timezoneHourOffset >= 0) {
          hourComponent = '+$hourComponent';
        } else {
          hourComponent = '-$hourComponent';
        }

        final timezoneString = [hourComponent, minuteComponent].join(':');
        string = [string, timezoneString].join('');
      }
    }

    if (value.year <= 0) {
      // Postgres has no year 0 and expects a "BC" suffix instead of a
      // leading minus sign for years before 1 AD. Dart's astronomical year
      // numbering (year 0 = 1 BC, year -1 = 2 BC, ...) must be converted to
      // Postgres's BC year (`1 - year`) - just moving the sign into a
      // suffix without adjusting the year would be off by one for every BC
      // date.
      final bcYear = 1 - value.year;
      // `toIso8601String()` pads the year to at least 4 digits, optionally
      // preceded by a sign; skip index 0 so a leading '-' isn't mistaken for
      // the date separator, and use the tail (month/day/time/offset) as-is.
      final rest = string.substring(string.indexOf('-', 1));
      string = '${bcYear.toString().padLeft(4, '0')}$rest BC';
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

  String _encodeBytea(Uint8List value, bool escapeStrings) {
    final hex = StringBuffer(r'\x');
    for (final byte in value) {
      hex.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return _encodeString(hex.toString(), escapeStrings);
  }

  String _encodeList(List value) {
    if (value.isEmpty) {
      return '{}';
    }

    // Ignore `null` elements when inferring the element type - they're
    // written as the bare `NULL` keyword below regardless of type, and
    // shouldn't make the fold think the list has a mixed/unknown type.
    final nonNullValues = value.where((e) => e != null);
    if (nonNullValues.isEmpty) {
      return '{${value.map((_) => 'NULL').join(',')}}';
    }

    final first = nonNullValues.first as Object;
    final type = nonNullValues.fold(first.runtimeType, (type, item) {
      if (type == item.runtimeType) {
        return type;
      } else if ((type == int || type == double) && item is num) {
        return double;
      } else {
        return Map;
      }
    });

    String encodeElement(Object? item, String Function(Object value) encode) {
      return item == null ? 'NULL' : encode(item);
    }

    if (type == bool) {
      return '{${value.map((s) => encodeElement(s, (v) => (v as bool).toString())).join(',')}}';
    }

    if (type == int || type == double) {
      return '{${value.map((s) => encodeElement(s, (v) => v is double ? _encodeDouble(v) : _encodeNumber(v as num))).join(',')}}';
    }

    if (type == String) {
      return '{${value.map((s) => encodeElement(s, (v) {
        final escaped = (v as String).replaceAll(r'\', r'\\').replaceAll('"', r'\"');
        return '"$escaped"';
      })).join(',')}}';
    }

    if (type == Map) {
      return '{${value.map((s) => encodeElement(s, (v) {
        final escaped = json.encode(v).replaceAll(r'\', r'\\').replaceAll('"', r'\"');
        return '"$escaped"';
      })).join(',')}}';
    }

    throw PgException("Could not infer array type of value '$value'.");
  }
}

/// Parses a date/timestamp string as sent by Postgres, including its `BC`
/// suffix convention for years before 1 AD (which `DateTime.parse` doesn't
/// understand on its own).
DateTime _parseDateTimeText(String text) {
  const bcSuffix = ' BC';
  if (!text.endsWith(bcSuffix)) {
    return DateTime.parse(text);
  }

  final withoutSuffix = text.substring(0, text.length - bcSuffix.length);
  final yearEnd = withoutSuffix.indexOf('-');
  final bcYear = int.parse(withoutSuffix.substring(0, yearEnd));
  final rest = withoutSuffix.substring(yearEnd);

  // Postgres's BC year (`1` for 1 BC, `2` for 2 BC, ...) is the inverse of
  // Dart's astronomical year numbering (year 0 = 1 BC, year -1 = 2 BC, ...).
  final astronomicalYear = 1 - bcYear;
  final yearString = astronomicalYear < 0
      ? '-${(-astronomicalYear).toString().padLeft(4, '0')}'
      : astronomicalYear.toString().padLeft(4, '0');

  return DateTime.parse('$yearString$rest');
}

class PostgresTextDecoder {
  static Object? convert(CodecContext context, int typeOid, Uint8List di) {
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
        final raw = _parseDateTimeText(asText());
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
        final raw = _parseDateTimeText(asText());
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
