import 'dart:convert';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:latlong/latlong.dart';

import '../postgres.dart';
import 'types.dart';

final _bool0 = Uint8List(1)..[0] = 0;
final _bool1 = Uint8List(1)..[0] = 1;
final _dashUnit = '-'.codeUnits.first;
final _hex = <String>[
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  'a',
  'b',
  'c',
  'd',
  'e',
  'f',
];

class PostgresBinaryEncoder extends Converter<dynamic, Uint8List> {
  final PostgreSQLDataType _dataType;

  const PostgresBinaryEncoder(this._dataType);

  @override
  Uint8List convert(dynamic value) {
    if (value == null) {
      return null;
    }

    switch (_dataType) {
      case PostgreSQLDataType.boolean:
        {
          if (value is bool) {
            return value ? _bool1 : _bool0;
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: bool Got: ${value.runtimeType}');
        }
      case PostgreSQLDataType.bigSerial:
      case PostgreSQLDataType.bigInteger:
        {
          if (value is int) {
            final bd = ByteData(8);
            bd.setInt64(0, value);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: int Got: ${value.runtimeType}');
        }
      case PostgreSQLDataType.serial:
      case PostgreSQLDataType.integer:
        {
          if (value is int) {
            final bd = ByteData(4);
            bd.setInt32(0, value);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: int Got: ${value.runtimeType}');
        }
      case PostgreSQLDataType.smallInteger:
        {
          if (value is int) {
            final bd = ByteData(2);
            bd.setInt16(0, value);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: int Got: ${value.runtimeType}');
        }
      case PostgreSQLDataType.name:
      case PostgreSQLDataType.text:
        {
          if (value is String) {
            return castBytes(utf8.encode(value));
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: String Got: ${value.runtimeType}');
        }
      case PostgreSQLDataType.real:
        {
          if (value is double) {
            final bd = ByteData(4);
            bd.setFloat32(0, value);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: double Got: ${value.runtimeType}');
        }
      case PostgreSQLDataType.double:
        {
          if (value is double) {
            final bd = ByteData(8);
            bd.setFloat64(0, value);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: double Got: ${value.runtimeType}');
        }
      case PostgreSQLDataType.date:
        {
          if (value is DateTime) {
            final bd = ByteData(4);
            bd.setInt32(0, value.toUtc().difference(DateTime.utc(2000)).inDays);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: DateTime Got: ${value.runtimeType}');
        }

      case PostgreSQLDataType.timestampWithoutTimezone:
        {
          if (value is DateTime) {
            final bd = ByteData(8);
            final diff = value.toUtc().difference(DateTime.utc(2000));
            bd.setInt64(0, diff.inMicroseconds);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: DateTime Got: ${value.runtimeType}');
        }

      case PostgreSQLDataType.timestampWithTimezone:
        {
          if (value is DateTime) {
            final bd = ByteData(8);
            bd.setInt64(
                0, value.toUtc().difference(DateTime.utc(2000)).inMicroseconds);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: DateTime Got: ${value.runtimeType}');
        }

      case PostgreSQLDataType.jsonb:
        {
          final jsonBytes = utf8.encode(json.encode(value));
          final writer = ByteDataWriter(bufferLength: jsonBytes.length + 1);
          writer.writeUint8(1);
          writer.write(jsonBytes);
          return writer.toBytes();
        }

      case PostgreSQLDataType.json:
        return castBytes(utf8.encode(json.encode(value)));

      case PostgreSQLDataType.byteArray:
        {
          if (value is List<int>) {
            return castBytes(value);
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<int> Got: ${value.runtimeType}');
        }

      case PostgreSQLDataType.uuid:
        {
          if (value is! String) {
            throw FormatException(
                'Invalid type for parameter value. Expected: String Got: ${value.runtimeType}');
          }

          final hexBytes = (value as String)
              .toLowerCase()
              .codeUnits
              .where((c) => c != _dashUnit)
              .toList();
          if (hexBytes.length != 32) {
            throw FormatException(
                "Invalid UUID string. There must be exactly 32 hexadecimal (0-9 and a-f) characters and any number of '-' characters.");
          }

          final byteConvert = (int charCode) {
            if (charCode >= 48 && charCode <= 57) {
              return charCode - 48;
            } else if (charCode >= 97 && charCode <= 102) {
              return charCode - 87;
            }

            throw FormatException(
                'Invalid UUID string. Contains non-hexadecimal character (0-9 and a-f).');
          };

          final outBuffer = Uint8List(16);
          for (var i = 0, j = 0; i < hexBytes.length; i += 2, j++) {
            final upperByte = byteConvert(hexBytes[i]);
            final lowerByte = byteConvert(hexBytes[i + 1]);

            outBuffer[j] = (upperByte << 4) + lowerByte;
          }
          return outBuffer;
        }

      case PostgreSQLDataType.point:
        {
          if (value is LatLng) {
            final bd = ByteData(16);
            bd.setFloat64(0, value.latitude);
            bd.setFloat64(8, value.longitude);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: LatLng Got: ${value.runtimeType}');
        }

      case PostgreSQLDataType.integerArray:
        {
          if (value is List<int>) {
            return writeListBytes<int>(value, 23, (_) => 4,
                (bd, offset, item) => bd.setInt32(offset, item));
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<int> Got: ${value.runtimeType}');
        }

      case PostgreSQLDataType.textArray:
        {
          if (value is List<String>) {
            final bytesArray = value.map((v) => castBytes(utf8.encode(v)));
            return writeListBytes<Uint8List>(
                bytesArray, 25, (item) => item.length, (bd, offset, item) {
              item.forEach((i) => bd.setUint8(offset++, i));
            });
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<String> Got: ${value.runtimeType}');
        }

      case PostgreSQLDataType.doubleArray:
        {
          if (value is List<double>) {
            return writeListBytes<double>(value, 701, (_) => 8,
                (bd, offset, item) => bd.setFloat64(offset, item));
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<double> Got: ${value.runtimeType}');
        }
    }

    throw PostgreSQLException('Unsupported datatype');
  }
}

Uint8List writeListBytes<T>(
    Iterable<T> value,
    int type,
    int Function(T item) lengthEncoder,
    void Function(ByteData bd, int offset, T item) valueEncoder) {
  final bd =
      ByteData(20 + value.fold<int>(0, (sum, item) => 4 + lengthEncoder(item)));
  bd.setInt32(0, 1); // dimension
  bd.setInt32(4, 0); // ign
  bd.setInt32(8, type); // type
  bd.setInt32(12, value.length); // size
  bd.setInt32(16, 1); // index
  var offset = 20;
  for (var i in value) {
    final len = lengthEncoder(i);
    bd.setInt32(offset, len); // value length
    valueEncoder(bd, offset + 4, i); // value
    offset += 4 + len;
  }
  return bd.buffer.asUint8List();
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

    final buffer =
        ByteData.view(value.buffer, value.offsetInBytes, value.lengthInBytes);

    switch (dataType) {
      case PostgreSQLDataType.name:
      case PostgreSQLDataType.text:
        return utf8.decode(value);
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
        return DateTime.utc(2000)
            .add(Duration(microseconds: buffer.getInt64(0)));

      case PostgreSQLDataType.date:
        return DateTime.utc(2000).add(Duration(days: buffer.getInt32(0)));

      case PostgreSQLDataType.jsonb:
        {
          // Removes version which is first character and currently always '1'
          final bytes = value.buffer
              .asUint8List(value.offsetInBytes + 1, value.lengthInBytes - 1);
          return json.decode(utf8.decode(bytes));
        }

      case PostgreSQLDataType.json:
        return json.decode(utf8.decode(value));

      case PostgreSQLDataType.byteArray:
        return value;

      case PostgreSQLDataType.uuid:
        {
          final buf = StringBuffer();
          for (var i = 0; i < buffer.lengthInBytes; i++) {
            final byteValue = buffer.getUint8(i);
            final upperByteValue = byteValue >> 4;
            final lowerByteValue = byteValue & 0x0f;

            final upperByteHex = _hex[upperByteValue];
            final lowerByteHex = _hex[lowerByteValue];
            buf.write(upperByteHex);
            buf.write(lowerByteHex);
            if (i == 3 || i == 5 || i == 7 || i == 9) {
              buf.writeCharCode(_dashUnit);
            }
          }

          return buf.toString();
        }

      case PostgreSQLDataType.point:
        return LatLng(buffer.getFloat64(0), buffer.getFloat64(8));

      case PostgreSQLDataType.integerArray:
        return readListBytes<int>(
            buffer, (offset, _) => buffer.getInt32(offset));

      case PostgreSQLDataType.textArray:
        return readListBytes<String>(
            buffer,
            (offset, length) =>
                utf8.decode(value.sublist(offset, offset + length)));

      case PostgreSQLDataType.doubleArray:
        return readListBytes<double>(
            buffer, (offset, _) => buffer.getFloat64(offset));
    }

    // prepend type-code and return raw bytes

    final writer = ByteDataWriter(bufferLength: value.length + 4);
    writer.writeUint32(typeCode);
    writer.write(value);
    return writer.toBytes();
  }

  List<T> readListBytes<T>(
      ByteData buffer, T Function(int offset, int length) valueDecoder) {
    final decoded = [].cast<T>();

    final size = buffer.getInt32(12);

    var offset = 20;
    for (var i = 0; i <= size; i++) {
      final len = buffer.getInt32(offset);
      decoded.add(valueDecoder(offset + 4, len));
      offset += 4 + len;
    }

    return decoded;
  }

  static final Map<int, PostgreSQLDataType> typeMap = {
    16: PostgreSQLDataType.boolean,
    17: PostgreSQLDataType.byteArray,
    19: PostgreSQLDataType.name,
    20: PostgreSQLDataType.bigInteger,
    21: PostgreSQLDataType.smallInteger,
    23: PostgreSQLDataType.integer,
    25: PostgreSQLDataType.text,
    114: PostgreSQLDataType.json,
    600: PostgreSQLDataType.point,
    700: PostgreSQLDataType.real,
    701: PostgreSQLDataType.double,
    1007: PostgreSQLDataType.integerArray,
    1009: PostgreSQLDataType.textArray,
    1022: PostgreSQLDataType.doubleArray,
    1082: PostgreSQLDataType.date,
    1114: PostgreSQLDataType.timestampWithoutTimezone,
    1184: PostgreSQLDataType.timestampWithTimezone,
    2950: PostgreSQLDataType.uuid,
    3802: PostgreSQLDataType.jsonb,
  };
}
