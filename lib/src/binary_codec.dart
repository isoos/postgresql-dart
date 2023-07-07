import 'dart:convert';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:postgres/src/v3/types.dart';

import '../postgres.dart' show PostgreSQLException;
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
final _numericRegExp = RegExp(r'^(\d*)(\.\d*)?$');
final _leadingZerosRegExp = RegExp(r'^0+');
final _trailingZerosRegExp = RegExp(r'0+$');

class PostgresBinaryEncoder<T extends Object>
    extends Converter<T?, Uint8List?> {
  final PgDataType<T> _dataType;
  final Encoding encoding;

  const PostgresBinaryEncoder(this._dataType, this.encoding);

  @override
  Uint8List? convert(Object? input) {
     print('binary_codec@convert input $input');
    if (input == null) {
      return null;
    }

    // ignore: unnecessary_cast
    switch (_dataType as PgDataType<Object>) {
      case PgDataType.boolean:
        {
          if (input is bool) {
            return input ? _bool1 : _bool0;
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: bool Got: ${input.runtimeType}');
        }
      case PgDataType.bigSerial:
      case PgDataType.bigInteger:
        {
          if (input is int) {
            final bd = ByteData(8);
            bd.setInt64(0, input);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: int Got: ${input.runtimeType}');
        }
      case PgDataType.serial:
      case PgDataType.integer:
        {
          if (input is int) {
            final bd = ByteData(4);
            bd.setInt32(0, input);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: int Got: ${input.runtimeType}');
        }
      case PgDataType.smallInteger:
        {
          if (input is int) {
            final bd = ByteData(2);
            bd.setInt16(0, input);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: int Got: ${input.runtimeType}');
        }
      case PgDataType.name:
      case PgDataType.text:
      case PgDataType.varChar:
        {
          if (input is String) {
            print('binary_codec varChar encoding $encoding');
            return castBytes(encoding.encode(input));
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: String Got: ${input.runtimeType}');
        }
      case PgDataType.real:
        {
          if (input is double) {
            final bd = ByteData(4);
            bd.setFloat32(0, input);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: double Got: ${input.runtimeType}');
        }
      case PgDataType.double:
        {
          if (input is double) {
            final bd = ByteData(8);
            bd.setFloat64(0, input);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: double Got: ${input.runtimeType}');
        }
      case PgDataType.date:
        {
          if (input is DateTime) {
            final bd = ByteData(4);
            bd.setInt32(0, input.toUtc().difference(DateTime.utc(2000)).inDays);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: DateTime Got: ${input.runtimeType}');
        }

      case PgDataType.timestampWithoutTimezone:
        {
          if (input is DateTime) {
            final bd = ByteData(8);
            final diff = input.toUtc().difference(DateTime.utc(2000));
            bd.setInt64(0, diff.inMicroseconds);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: DateTime Got: ${input.runtimeType}');
        }

      case PgDataType.timestampWithTimezone:
        {
          if (input is DateTime) {
            final bd = ByteData(8);
            bd.setInt64(
                0, input.toUtc().difference(DateTime.utc(2000)).inMicroseconds);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: DateTime Got: ${input.runtimeType}');
        }

      case PgDataType.interval:
        {
          if (input is Duration) {
            final bd = ByteData(16);
            bd.setInt64(0, input.inMicroseconds);
            // ignoring the second 8 bytes
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: Duration Got: ${input.runtimeType}');
        }

      case PgDataType.numeric:
        {
          Object source = input;

          if (source is double || source is int) {
            source = input.toString();
          }
          if (source is String) {
            return _encodeNumeric(source);
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: String|double|int Got: ${input.runtimeType}');
        }

      case PgDataType.jsonb:
        {
          final jsonBytes = encoding.encode(json.encode(input));
          final writer = ByteDataWriter(bufferLength: jsonBytes.length + 1);
          writer.writeUint8(1);
          writer.write(jsonBytes);
          return writer.toBytes();
        }

      case PgDataType.json:
        return castBytes(encoding.encode(json.encode(input)));

      case PgDataType.byteArray:
        {
          if (input is List<int>) {
            return castBytes(input);
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<int> Got: ${input.runtimeType}');
        }

      case PgDataType.uuid:
        {
          if (input is! String) {
            throw FormatException(
                'Invalid type for parameter value. Expected: String Got: ${input.runtimeType}');
          }

          final hexBytes = input
              .toLowerCase()
              .codeUnits
              .where((c) => c != _dashUnit)
              .toList();
          if (hexBytes.length != 32) {
            throw FormatException(
                "Invalid UUID string. There must be exactly 32 hexadecimal (0-9 and a-f) characters and any number of '-' characters.");
          }

          int byteConvert(int charCode) {
            if (charCode >= 48 && charCode <= 57) {
              return charCode - 48;
            } else if (charCode >= 97 && charCode <= 102) {
              return charCode - 87;
            }

            throw FormatException(
                'Invalid UUID string. Contains non-hexadecimal character (0-9 and a-f).');
          }

          final outBuffer = Uint8List(16);
          for (var i = 0, j = 0; i < hexBytes.length; i += 2, j++) {
            final upperByte = byteConvert(hexBytes[i]);
            final lowerByte = byteConvert(hexBytes[i + 1]);

            outBuffer[j] = (upperByte << 4) + lowerByte;
          }
          return outBuffer;
        }

      case PgDataType.point:
        {
          if (input is PgPoint) {
            final bd = ByteData(16);
            bd.setFloat64(0, input.latitude);
            bd.setFloat64(8, input.longitude);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: PgPoint Got: ${input.runtimeType}');
        }

      case PgDataType.booleanArray:
        {
          if (input is List<bool>) {
            return writeListBytes<bool>(input, 16, (_) => 1,
                (writer, item) => writer.writeUint8(item ? 1 : 0));
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<bool> Got: ${input.runtimeType}');
        }

      case PgDataType.integerArray:
        {
          if (input is List<int>) {
            return writeListBytes<int>(
                input, 23, (_) => 4, (writer, item) => writer.writeInt32(item));
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<int> Got: ${input.runtimeType}');
        }

      case PgDataType.bigIntegerArray:
        {
          if (input is List<int>) {
            return writeListBytes<int>(
                input, 20, (_) => 8, (writer, item) => writer.writeInt64(item));
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<int> Got: ${input.runtimeType}');
        }

      case PgDataType.varCharArray:
        {
          if (input is List<String>) {
            final bytesArray = input.map((v) => encoding.encode(v));
            return writeListBytes<List<int>>(bytesArray, 1043,
                (item) => item.length, (writer, item) => writer.write(item));
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<String> Got: ${input.runtimeType}');
        }

      case PgDataType.textArray:
        {
          if (input is List<String>) {
            final bytesArray = input.map((v) => encoding.encode(v));
            return writeListBytes<List<int>>(bytesArray, 25,
                (item) => item.length, (writer, item) => writer.write(item));
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<String> Got: ${input.runtimeType}');
        }

      case PgDataType.doubleArray:
        {
          if (input is List<double>) {
            return writeListBytes<double>(input, 701, (_) => 8,
                (writer, item) => writer.writeFloat64(item));
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<double> Got: ${input.runtimeType}');
        }

      case PgDataType.jsonbArray:
        {
          if (input is List<Object>) {
            final objectsArray = input.map((v) => encoding.encode(json.encode(v)));
            return writeListBytes<List<int>>(
                objectsArray, 3802, (item) => item.length + 1, (writer, item) {
              writer.writeUint8(1);
              writer.write(item);
            });
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<Object> Got: ${input.runtimeType}');
        }

      default:
        throw PostgreSQLException('Unsupported datatype');
    }
  }

  Uint8List writeListBytes<V>(
      Iterable<V> value,
      int type,
      int Function(V item) lengthEncoder,
      void Function(ByteDataWriter writer, V item) valueEncoder) {
    final writer = ByteDataWriter();

    writer.writeInt32(1); // dimension
    writer.writeInt32(0); // ign
    writer.writeInt32(type); // type
    writer.writeInt32(value.length); // size
    writer.writeInt32(1); // index

    for (var i in value) {
      final len = lengthEncoder(i);
      writer.writeInt32(len);
      valueEncoder(writer, i);
    }

    return writer.toBytes();
  }

  /// Encode String / double / int to numeric / decimal  without loosing precision.
  /// Compare implementation: https://github.com/frohoff/jdk8u-dev-jdk/blob/da0da73ab82ed714dc5be94acd2f0d00fbdfe2e9/src/share/classes/java/math/BigDecimal.java#L409
  Uint8List _encodeNumeric(String value) {
    value = value.trim();
    var signByte = 0x0000;
    if (value.toLowerCase() == 'nan') {
      signByte = 0xc000;
      value = '';
    } else if (value.startsWith('-')) {
      value = value.substring(1);
      signByte = 0x4000;
    } else if (value.startsWith('+')) {
      value = value.substring(1);
    }
    if (!_numericRegExp.hasMatch(value)) {
      throw FormatException(
          'Invalid format for parameter value. Expected: String which matches "/^(\\d*)(\\.\\d*)?\$/" Got: $value');
    }
    final parts = value.split('.');

    var intPart = parts[0].replaceAll(_leadingZerosRegExp, '');
    var intWeight = intPart.isEmpty ? -1 : (intPart.length - 1) ~/ 4;
    intPart = intPart.padLeft((intWeight + 1) * 4, '0');

    var fractPart = parts.length > 1 ? parts[1] : '';
    final dScale = fractPart.length;
    fractPart = fractPart.replaceAll(_trailingZerosRegExp, '');
    var fractWeight = fractPart.isEmpty ? -1 : (fractPart.length - 1) ~/ 4;
    fractPart = fractPart.padRight((fractWeight + 1) * 4, '0');

    var weight = intWeight;
    if (intWeight < 0) {
      // If int part has no weight, handle leading zeros in fractional part.
      if (fractPart.isEmpty) {
        // Weight of value 0 or '' is 0;
        weight = 0;
      } else {
        final leadingZeros =
            _leadingZerosRegExp.firstMatch(fractPart)?.group(0);
        if (leadingZeros != null) {
          final leadingZerosWeight =
              leadingZeros.length ~/ 4; // Get count of leading zeros '0000'
          fractPart = fractPart
              .substring(leadingZerosWeight * 4); // Remove leading zeros '0000'
          fractWeight -= leadingZerosWeight;
          weight = -(leadingZerosWeight + 1); // Ignore leading zeros in weight
        }
      }
    } else if (fractWeight < 0) {
      // If int fract has no weight, handle trailing zeros in int part.
      final trailingZeros = _trailingZerosRegExp.firstMatch(intPart)?.group(0);
      if (trailingZeros != null) {
        final trailingZerosWeight =
            trailingZeros.length ~/ 4; // Get count of trailing zeros '0000'
        intPart = intPart.substring(
            0,
            intPart.length -
                trailingZerosWeight * 4); // Remove leading zeros '0000'
        intWeight -= trailingZerosWeight;
      }
    }

    final nDigits = intWeight + fractWeight + 2;

    final writer = ByteDataWriter();
    writer.writeInt16(nDigits);
    writer.writeInt16(weight);
    writer.writeUint16(signByte);
    writer.writeInt16(dScale);
    for (var i = 0; i <= intWeight * 4; i += 4) {
      writer.writeInt16(int.parse(intPart.substring(i, i + 4)));
    }
    for (var i = 0; i <= fractWeight * 4; i += 4) {
      writer.writeInt16(int.parse(fractPart.substring(i, i + 4)));
    }
    return writer.toBytes();
  }
}

class PostgresBinaryDecoder<T> extends Converter<Uint8List?, T?> {
  const PostgresBinaryDecoder(this.typeCode, this.encoding);

  final int typeCode;
  final Encoding encoding;

  @override
  T? convert(Uint8List? input) {
    if (input == null) {
      return null;
    }

    final dataType = typeMap[typeCode];

    final buffer =
        ByteData.view(input.buffer, input.offsetInBytes, input.lengthInBytes);

    switch (dataType) {
      case PostgreSQLDataType.name:
      case PostgreSQLDataType.text:
      case PostgreSQLDataType.varChar:
        return encoding.decode(input) as T;
      case PostgreSQLDataType.boolean:
        return (buffer.getInt8(0) != 0) as T;
      case PostgreSQLDataType.smallInteger:
        return buffer.getInt16(0) as T;
      case PostgreSQLDataType.serial:
      case PostgreSQLDataType.integer:
        return buffer.getInt32(0) as T;
      case PostgreSQLDataType.bigSerial:
      case PostgreSQLDataType.bigInteger:
        return buffer.getInt64(0) as T;
      case PostgreSQLDataType.real:
        return buffer.getFloat32(0) as T;
      case PostgreSQLDataType.double:
        return buffer.getFloat64(0) as T;
      case PostgreSQLDataType.timestampWithoutTimezone:
      case PostgreSQLDataType.timestampWithTimezone:
        return DateTime.utc(2000)
            .add(Duration(microseconds: buffer.getInt64(0))) as T;

      case PostgreSQLDataType.interval:
        {
          if (buffer.getInt64(8) != 0) throw UnimplementedError();
          return Duration(microseconds: buffer.getInt64(0)) as T;
        }

      case PostgreSQLDataType.numeric:
        return _decodeNumeric(input) as T;

      case PostgreSQLDataType.date:
        return DateTime.utc(2000).add(Duration(days: buffer.getInt32(0))) as T;

      case PostgreSQLDataType.jsonb:
        {
          // Removes version which is first character and currently always '1'
          final bytes = input.buffer
              .asUint8List(input.offsetInBytes + 1, input.lengthInBytes - 1);
          return json.decode(encoding.decode(bytes)) as T;
        }

      case PostgreSQLDataType.json:
        return json.decode(encoding.decode(input)) as T;

      case PostgreSQLDataType.byteArray:
        return input as T;

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

          return buf.toString() as T;
        }

      case PostgreSQLDataType.point:
        return PgPoint(buffer.getFloat64(0), buffer.getFloat64(8)) as T;

      case PostgreSQLDataType.booleanArray:
        return readListBytes<bool>(
            input, (reader, _) => reader.readUint8() != 0) as T;

      case PostgreSQLDataType.integerArray:
        return readListBytes<int>(input, (reader, _) => reader.readInt32())
            as T;
      case PostgreSQLDataType.bigIntegerArray:
        return readListBytes<int>(input, (reader, _) => reader.readInt64())
            as T;

      case PostgreSQLDataType.varCharArray:
      case PostgreSQLDataType.textArray:
        return readListBytes<String>(input, (reader, length) {
          return encoding.decode(length > 0 ? reader.read(length) : []);
        }) as T;

      case PostgreSQLDataType.doubleArray:
        return readListBytes<double>(input, (reader, _) => reader.readFloat64())
            as T;

      case PostgreSQLDataType.jsonbArray:
        return readListBytes<dynamic>(input, (reader, length) {
          reader.read(1);
          final bytes = reader.read(length - 1);
          return json.decode(encoding.decode(bytes));
        }) as T;

      default:
        {
          // We'll try and decode this as a utf8 string and return that
          // for many internal types, this is valid. If it fails,
          // we just return the bytes and let the caller figure out what to
          // do with it.
          try {
            return encoding.decode(input) as T;
          } catch (_) {
            return input as T;
          }
        }
    }
  }

  List<V> readListBytes<V>(Uint8List data,
      V Function(ByteDataReader reader, int length) valueDecoder) {
    if (data.length < 16) {
      return [];
    }

    final reader = ByteDataReader()..add(data);
    reader.read(12); // header

    final decoded = [].cast<V>();
    final size = reader.readInt32();

    reader.read(4); // index

    for (var i = 0; i < size; i++) {
      final len = reader.readInt32();
      decoded.add(valueDecoder(reader, len));
    }

    return decoded;
  }

  /// See: https://github.com/postgres/postgres/blob/master/src/include/catalog/pg_type.dat
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
    1000: PostgreSQLDataType.booleanArray,
    1007: PostgreSQLDataType.integerArray,
    1016: PostgreSQLDataType.bigIntegerArray,
    1009: PostgreSQLDataType.textArray,
    1015: PostgreSQLDataType.varCharArray,
    1043: PostgreSQLDataType.varChar,
    1022: PostgreSQLDataType.doubleArray,
    1082: PostgreSQLDataType.date,
    1114: PostgreSQLDataType.timestampWithoutTimezone,
    1184: PostgreSQLDataType.timestampWithTimezone,
    1186: PostgreSQLDataType.interval,
    1700: PostgreSQLDataType.numeric,
    2950: PostgreSQLDataType.uuid,
    3802: PostgreSQLDataType.jsonb,
    3807: PostgreSQLDataType.jsonbArray,
  };

  /// Decode numeric / decimal to String without loosing precision.
  /// See encoding: https://github.com/postgres/postgres/blob/0e39a608ed5545cc6b9d538ac937c3c1ee8cdc36/src/backend/utils/adt/numeric.c#L305
  /// See implementation: https://github.com/charmander/pg-numeric/blob/0c310eeb11dc680dffb7747821e61d542831108b/index.js#L13
  static String _decodeNumeric(Uint8List value) {
    final reader = ByteDataReader()..add(value);
    final nDigits =
        reader.readInt16(); // non-zero digits, data buffer length = 2 * nDigits
    var weight = reader.readInt16(); // weight of first digit
    final signByte =
        reader.readUint16(); // NUMERIC_POS, NEG, NAN, PINF, or NINF
    final dScale = reader.readInt16(); // display scale
    if (signByte == 0xc000) return 'NaN';
    final sign = signByte == 0x4000 ? '-' : '';
    var intPart = '';
    var fractPart = '';

    final fractOmitted = -(weight + 1);
    if (fractOmitted > 0) {
      // If value < 0, the leading zeros in fractional part were omitted.
      fractPart += '0000' * fractOmitted;
    }

    for (var i = 0; i < nDigits; i++) {
      if (weight >= 0) {
        intPart += reader.readInt16().toString().padLeft(4, '0');
      } else {
        fractPart += reader.readInt16().toString().padLeft(4, '0');
      }
      weight--;
    }

    if (weight >= 0) {
      // Trailing zeros were omitted
      intPart += '0000' * (weight + 1);
    }

    var result = '$sign${intPart.replaceAll(_leadingZerosRegExp, '')}';
    if (result.isEmpty) {
      result = '0'; // Show at least 0, if no int value is given.
    }
    if (dScale > 0) {
      // Only add fractional digits, if dScale allows
      result += '.${fractPart.padRight(dScale, '0').substring(0, dScale)}';
    }
    return result;
  }
}
