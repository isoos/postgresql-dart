part of postgres;

enum PostgreSQLDataType {
  text,
  integer, smallInteger, bigInteger,
  serial, bigSerial,
  real, double,
  boolean,
  timestampWithoutTimezone, timestampWithTimezone
}

class PostgreSQLCodec {
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

  static final RegExp escapeExpression = new RegExp(r"['\r\n\\]");

  static const Map<int, String> escapeCharacters = const {
    39 : r"\'",
    13 : r"\r",
    10 : r"\n",
    92 : r"\\"
  };

  static String encode(dynamic value, {PostgreSQLDataType dataType: null}) {
    if (value == null) {
      return "null";
    }

    switch (dataType) {
      case PostgreSQLDataType.text:
        return encodeString(value.toString());

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
        return encodeDateTime(value);

      default:
        return encodeDefault(value);
    }
  }

  static Uint8List encodeBinary(dynamic value, int postgresType) {
    if (value == null) {
      return null;
    }

    Uint8List outBuffer = null;

    if (postgresType == TypeBool) {
      var bd = new ByteData(1);
      bd.setUint8(0, value ? 1 : 0);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeInt8) {
      var bd = new ByteData(8);
      bd.setInt64(0, value);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeInt2) {
      var bd = new ByteData(2);
      bd.setInt16(0, value);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeInt4) {
      var bd = new ByteData(4);
      bd.setInt32(0, value);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeText) {
      String val = value;
      outBuffer = new Uint8List.fromList(val.codeUnits);
    } else if (postgresType == TypeFloat4) {
      var bd = new ByteData(4);
      bd.setFloat32(0, value);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeFloat8) {
      var bd = new ByteData(8);
      bd.setFloat64(0, value);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeDate) {
      DateTime dt = value;
      var bd = new ByteData(4);
      bd.setInt32(0, dt.toUtc().difference(new DateTime.utc(2000)).inDays);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeTimestamp) {
      DateTime dt = value;
      var bd = new ByteData(8);
      var diff = dt.toUtc().difference(new DateTime.utc(2000));
      bd.setInt64(0, diff.inMicroseconds);
      outBuffer = bd.buffer.asUint8List();
    } else if (postgresType == TypeTimestampTZ) {
      DateTime dt = value;
      var bd = new ByteData(8);
      bd.setInt64(0, dt.toUtc().difference(new DateTime.utc(2000)).inMicroseconds);
      outBuffer = bd.buffer.asUint8List();
    }

    return outBuffer;
  }

  static String encodeString(String text) {
    var escaped = text.replaceAllMapped(escapeExpression, (m) {
      return escapeCharacters[text.codeUnitAt(m.start)];
    });

    return "E'$escaped'";
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

  static String encodeDefault(dynamic value) {
    if (value == null) {
      return 'null';
    }

    if (value is int) {
      return encodeNumber(value);
    }

    if (value is double) {
      return encodeDouble(value);
    }

    if (value is String) {
      return encodeString(value);
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