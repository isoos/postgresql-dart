import 'dart:convert';

import 'dart:typed_data';

import 'package:postgres/postgres.dart';
import 'package:postgres/src/types.dart';

class PostgresBinaryEncoder extends Converter<dynamic, Uint8List> {
  const PostgresBinaryEncoder(this.dataType);

  final PostgreSQLDataType dataType;

  @override
  Uint8List convert(dynamic value) {
    if (value == null) {
      return null;
    }

    switch (dataType) {
      case PostgreSQLDataType.boolean: {
        if (value is! bool) {
          throw new FormatException(
            "Invalid type for parameter value. Expected: bool Got: ${value
              .runtimeType}");
        }

        var bd = new ByteData(1);
        bd.setUint8(0, value ? 1 : 0);
        return bd.buffer.asUint8List();
      }
      case PostgreSQLDataType.bigSerial:
      case PostgreSQLDataType.bigInteger: {
        if (value is! int) {
          throw new FormatException(
            "Invalid type for parameter value. Expected: int Got: ${value
              .runtimeType}");
        }

        var bd = new ByteData(8);
        bd.setInt64(0, value);
        return bd.buffer.asUint8List();
      }
      case PostgreSQLDataType.serial:
      case PostgreSQLDataType.integer: {
        if (value is! int) {
          throw new FormatException(
            "Invalid type for parameter value. Expected: int Got: ${value
              .runtimeType}");
        }

        var bd = new ByteData(4);
        bd.setInt32(0, value);
        return bd.buffer.asUint8List();
      }
      case PostgreSQLDataType.smallInteger: {
        if (value is! int) {
          throw new FormatException(
            "Invalid type for parameter value. Expected: int Got: ${value
              .runtimeType}");
        }

        var bd = new ByteData(2);
        bd.setInt16(0, value);
        return bd.buffer.asUint8List();
      }
      case PostgreSQLDataType.text: {
        if (value is! String) {
          throw new FormatException(
            "Invalid type for parameter value. Expected: String Got: ${value
              .runtimeType}");
        }

        return UTF8.encode(value);
      }
      case PostgreSQLDataType.real: {
        if (value is! double) {
          throw new FormatException(
            "Invalid type for parameter value. Expected: double Got: ${value
              .runtimeType}");
        }

        var bd = new ByteData(4);
        bd.setFloat32(0, value);
        return bd.buffer.asUint8List();
      }
      case PostgreSQLDataType.double: {
        if (value is! double) {
          throw new FormatException(
            "Invalid type for parameter value. Expected: double Got: ${value
              .runtimeType}");
        }

        var bd = new ByteData(8);
        bd.setFloat64(0, value);
        return bd.buffer.asUint8List();
      }
      case PostgreSQLDataType.date: {
        if (value is! DateTime) {
          throw new FormatException(
            "Invalid type for parameter value. Expected: DateTime Got: ${value
              .runtimeType}");
        }

        var bd = new ByteData(4);
        bd.setInt32(0, value.toUtc().difference(new DateTime.utc(2000)).inDays);
        return bd.buffer.asUint8List();
      }

      case PostgreSQLDataType.timestampWithoutTimezone: {
        if (value is! DateTime) {
          throw new FormatException(
            "Invalid type for parameter value. Expected: DateTime Got: ${value
              .runtimeType}");
        }

        var bd = new ByteData(8);
        var diff = value.toUtc().difference(new DateTime.utc(2000));
        bd.setInt64(0, diff.inMicroseconds);
        return bd.buffer.asUint8List();
      }

      case PostgreSQLDataType.timestampWithTimezone: {
        if (value is! DateTime) {
          throw new FormatException(
            "Invalid type for parameter value. Expected: DateTime Got: ${value
              .runtimeType}");
        }

        var bd = new ByteData(8);
        bd.setInt64(
          0, value.toUtc().difference(new DateTime.utc(2000)).inMicroseconds);
        return bd.buffer.asUint8List();
      }

      case PostgreSQLDataType.json: {
        var jsonBytes = UTF8.encode(JSON.encode(value));
        final outBuffer = new Uint8List(jsonBytes.length + 1);
        outBuffer[0] = 1;
        for (var i = 0; i < jsonBytes.length; i++) {
          outBuffer[i + 1] = jsonBytes[i];
        }

        return outBuffer;
      }

      case PostgreSQLDataType.byteArray: {
        if (value is! List) {
          throw new FormatException(
            "Invalid type for parameter value. Expected: List<int> Got: ${value
              .runtimeType}");
        }
        return new Uint8List.fromList(value);
      }
    }

    throw new PostgreSQLException("Unsupported datatype");
  }
}

class PostgresBinaryDecoder extends Converter<Uint8List, dynamic> {
  const PostgresBinaryDecoder(this.typeCode);

  final int typeCode;

  @override
  dynamic convert(Uint8List value) {
    final dataType = typeMap[typeCode];

    if (value == null) {
      return null;
    }

    final buffer = new ByteData.view(value.buffer, value.offsetInBytes, value.lengthInBytes);

    switch (dataType) {
      case PostgreSQLDataType.text:
        return UTF8.decode(value.buffer.asUint8List(value.offsetInBytes, value.lengthInBytes));
      case PostgreSQLDataType.boolean:
        return buffer.getInt8(0) != 0;
      case PostgreSQLDataType.smallInteger:
        return buffer.getInt16(0);
      case PostgreSQLDataType.serial:
      case PostgreSQLDataType.integer:
        return buffer.getInt32(0);
      case PostgreSQLDataType.bigSerial:
      case PostgreSQLDataType.bigInteger:
        return buffer.getInt64(0);
      case PostgreSQLDataType.real:
        return buffer.getFloat32(0);
      case PostgreSQLDataType.double:
        return buffer.getFloat64(0);
      case PostgreSQLDataType.timestampWithoutTimezone:
      case PostgreSQLDataType.timestampWithTimezone:
        return new DateTime.utc(2000)
          .add(new Duration(microseconds: buffer.getInt64(0)));

      case PostgreSQLDataType.date:
        return new DateTime.utc(2000)
          .add(new Duration(days: buffer.getInt32(0)));

      case PostgreSQLDataType.json: {
        // Removes version which is first character and currently always '1'
        final bytes = value.buffer.asUint8List(value.offsetInBytes + 1, value.lengthInBytes - 1);
        return JSON.decode(UTF8.decode(bytes));
      }

      case PostgreSQLDataType.byteArray:
        return value.buffer.asUint8List(value.offsetInBytes, value.lengthInBytes);
    }

    return value;
  }

  static final Map<int, PostgreSQLDataType> typeMap = {
    16: PostgreSQLDataType.boolean,
    17: PostgreSQLDataType.byteArray,
    20: PostgreSQLDataType.bigInteger,
    21: PostgreSQLDataType.smallInteger,
    23: PostgreSQLDataType.integer,
    25: PostgreSQLDataType.text,
    700: PostgreSQLDataType.real,
    701: PostgreSQLDataType.double,
    1082: PostgreSQLDataType.date,
    1114: PostgreSQLDataType.timestampWithoutTimezone,
    1184: PostgreSQLDataType.timestampWithTimezone,
    3802: PostgreSQLDataType.json
  };
}