part of postgres;

/// The set of available data types that [PostgreSQLConnection]s support.
enum PostgreSQLDataType {
  /// Must be a [String].
  text,

  /// Must be an [int] (4-byte integer)
  integer,

  /// Must be an [int] (2-byte integer)
  smallInteger,

  /// Must be an [int] (8-byte integer)
  bigInteger,

  /// Must be an [int] (autoincrementing 4-byte integer)
  serial,

  /// Must be an [int] (autoincrementing 8-byte integer)
  bigSerial,

  /// Must be a [double] (32-bit floating point value)
  real,

  /// Must be a [double] (64-bit floating point value)
  double,

  /// Must be a [bool]
  boolean,

  /// Must be a [DateTime] (microsecond date and time precision)
  timestampWithoutTimezone,

  /// Must be a [DateTime] (microsecond date and time precision)
  timestampWithTimezone,

  /// Must be a [DateTime] (contains year, month and day only)
  date
}

/// A namespace for data encoding and decoding operations for PostgreSQL data.
abstract class PostgreSQLCodec {
  static const int TypeBool = 16;
  static const int TypeInt8 = 20;
  static const int TypeInt2 = 21;
  static const int TypeInt4 = 23;
  static const int TypeText = 25;
  static const int TypeFloat4 = 700;
  static const int TypeFloat8 = 701;
  static const int TypeDate = 1082;
  static const int TypeTimestamp = 1114;
  static const int TypeTimestampTZ = 1184;

  static String encode(dynamic value, {PostgreSQLDataType dataType: null, bool escapeStrings: true}) {
    if (value == null) {
      return "null";
    }

    switch (dataType) {
      case PostgreSQLDataType.text:
        return encodeString(value.toString(), escapeStrings);

      case PostgreSQLDataType.integer:
      case PostgreSQLDataType.smallInteger:
      case PostgreSQLDataType.bigInteger:
      case PostgreSQLDataType.serial:
      case PostgreSQLDataType.bigSerial:
        return encodeNumber(value);

      case PostgreSQLDataType.double:
      case PostgreSQLDataType.real:
        return encodeDouble(value);

      case PostgreSQLDataType.boolean:
        return encodeBoolean(value);

      case PostgreSQLDataType.timestampWithoutTimezone:
      case PostgreSQLDataType.timestampWithTimezone:
      case PostgreSQLDataType.date:
        return encodeDateTime(value);

      default:
        return encodeDefault(value, escapeStrings: escapeStrings);
    }
  }

  static Uint8List encodeBinary(dynamic value, int postgresType) {
    if (value == null) {
      return null;
    }

    Uint8List outBuffer = null;

    if (postgresType == TypeBool) {
      if (value is! bool) {
        throw new FormatException("Invalid type for parameter value. Expected: bool Got: ${value.runtimeType}");
      }

      var bd = new ByteData(1);
      bd.setUint8(0, value ? 1 : 0);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeInt8) {
      if (value is! int) {
        throw new FormatException("Invalid type for parameter value. Expected: int Got: ${value.runtimeType}");
      }

      var bd = new ByteData(8);
      bd.setInt64(0, value);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeInt2) {
      if (value is! int) {
        throw new FormatException("Invalid type for parameter value. Expected: int Got: ${value.runtimeType}");
      }

      var bd = new ByteData(2);
      bd.setInt16(0, value);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeInt4) {
      if (value is! int) {
        throw new FormatException("Invalid type for parameter value. Expected: int Got: ${value.runtimeType}");
      }

      var bd = new ByteData(4);
      bd.setInt32(0, value);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeText) {
      if (value is! String) {
        throw new FormatException("Invalid type for parameter value. Expected: String Got: ${value.runtimeType}");
      }

      String val = value;
      outBuffer = new Uint8List.fromList(val.codeUnits);
    } else if (postgresType == TypeFloat4) {
      if (value is! double) {
        throw new FormatException("Invalid type for parameter value. Expected: double Got: ${value.runtimeType}");
      }

      var bd = new ByteData(4);
      bd.setFloat32(0, value);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeFloat8) {
      if (value is! double) {
        throw new FormatException("Invalid type for parameter value. Expected: double Got: ${value.runtimeType}");
      }

      var bd = new ByteData(8);
      bd.setFloat64(0, value);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeDate) {
      if (value is! DateTime) {
        throw new FormatException("Invalid type for parameter value. Expected: DateTime Got: ${value.runtimeType}");
      }

      var bd = new ByteData(4);
      bd.setInt32(0, value.toUtc().difference(new DateTime.utc(2000)).inDays);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeTimestamp) {
      if (value is! DateTime) {
        throw new FormatException("Invalid type for parameter value. Expected: DateTime Got: ${value.runtimeType}");
      }

      var bd = new ByteData(8);
      var diff = value.toUtc().difference(new DateTime.utc(2000));
      bd.setInt64(0, diff.inMicroseconds);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeTimestampTZ) {
      if (value is! DateTime) {
        throw new FormatException("Invalid type for parameter value. Expected: DateTime Got: ${value.runtimeType}");
      }

      var bd = new ByteData(8);
      bd.setInt64(0, value.toUtc().difference(new DateTime.utc(2000)).inMicroseconds);
      outBuffer = bd.buffer.asUint8List();
    }

    return outBuffer;
  }

  static String encodeString(String text, bool escapeStrings) {
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
        backslashCount ++;
      } else if (it.current == quoteCodeUnit) {
        quoteCount ++;
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

  static String encodeNumber(dynamic value) {
    if (value is! num) {
      throw new PostgreSQLException("Trying to encode ${value.runtimeType}: $value as integer-like type.");
    }

    if (value.isNaN) {
      return "'nan'";
    }

    if (value.isInfinite) {
      return value.isNegative ? "'-infinity'" : "'infinity'";
    }

    return value.toInt().toString();
  }

  static String encodeDouble(dynamic value) {
    if (value is! num) {
      throw new PostgreSQLException("Trying to encode ${value.runtimeType}: $value as double-like type.");
    }

    if (value.isNaN) {
      return "'nan'";
    }

    if (value.isInfinite) {
      return value.isNegative ? "'-infinity'" : "'infinity'";
    }

    return value.toString();
  }

  static String encodeBoolean(dynamic value) {
    if (value is! bool) {
      throw new PostgreSQLException("Trying to encode ${value.runtimeType}: $value as boolean type.");
    }

    return value ? "TRUE" : "FALSE";
  }

  static String encodeDateTime(dynamic value, {bool isDateOnly: false}) {
    if (value is! DateTime) {
      throw new PostgreSQLException("Trying to encode ${value.runtimeType}: $value as date-like type.");
    }

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

  static String encodeDefault(dynamic value, {bool escapeStrings: true}) {
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

    throw new PostgreSQLException("Unknown inferred datatype from ${value.runtimeType}: $value");
  }

  static dynamic decodeValue(ByteData value, int dbTypeCode) {
    if (value == null) {
      return null;
    }

    switch (dbTypeCode) {
      case TypeBool:
        return value.getInt8(0) != 0;
      case TypeInt2:
        return value.getInt16(0);
      case TypeInt4:
        return value.getInt32(0);
      case TypeInt8:
        return value.getInt64(0);
      case TypeFloat4:
        return value.getFloat32(0);
      case TypeFloat8:
        return value.getFloat64(0);

      case TypeTimestamp:
      case TypeTimestampTZ:
       return new DateTime.utc(2000).add(new Duration(microseconds: value.getInt64(0)));

      case TypeDate:
        return new DateTime.utc(2000).add(new Duration(days: value.getInt32(0)));

      default:
        return new String.fromCharCodes(value.buffer.asUint8List(value.offsetInBytes, value.lengthInBytes));
    }
  }
}