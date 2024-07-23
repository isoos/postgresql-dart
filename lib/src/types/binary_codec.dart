import 'dart:convert';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:pg_timezone/pg_timezone.dart' as tz;
import 'package:pg_timezone/timezone.dart' as tzenv;
import 'package:postgres/src/types/generic_type.dart';

import '../buffer.dart';
import '../types.dart';
import 'geo_types.dart';
import 'range_types.dart';
import 'type_registry.dart';

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
final _leadingZerosRegExp = RegExp('^0+');
final _trailingZerosRegExp = RegExp(r'0+$');

// The Dart SDK provides an optimized implementation for JSON from and to UTF-8
// that doesn't allocate intermediate strings.
final _jsonUtf8Codec = json.fuse(utf8);

Codec<Object?, List<int>> _jsonFusedEncoding(Encoding encoding) {
  if (encoding == utf8) {
    return _jsonUtf8Codec;
  } else {
    return json.fuse(encoding);
  }
}

class PostgresBinaryEncoder {
  final int _typeOid;

  const PostgresBinaryEncoder(this._typeOid);

  Uint8List convert(Object? input, Encoding encoding) {
    switch (_typeOid) {
      case TypeOid.voidType:
        throw ArgumentError('Cannot encode `$input` into oid($_typeOid).');
      case TypeOid.boolean:
        {
          if (input is bool) {
            return input ? _bool1 : _bool0;
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: bool Got: ${input.runtimeType}');
        }
      case TypeOid.bigInteger:
        {
          if (input is int) {
            final bd = ByteData(8);
            bd.setInt64(0, input);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: int Got: ${input.runtimeType}');
        }
      case TypeOid.integer:
        {
          if (input is int) {
            final bd = ByteData(4);
            bd.setInt32(0, input);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: int Got: ${input.runtimeType}');
        }
      case TypeOid.smallInteger:
        {
          if (input is int) {
            final bd = ByteData(2);
            bd.setInt16(0, input);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: int Got: ${input.runtimeType}');
        }
      case TypeOid.character:
      case TypeOid.name:
      case TypeOid.text:
      case TypeOid.varChar:
        {
          if (input is String) {
            return castBytes(encoding.encode(input));
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: String Got: ${input.runtimeType}');
        }
      case TypeOid.real:
        {
          if (input is double) {
            final bd = ByteData(4);
            bd.setFloat32(0, input);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: double Got: ${input.runtimeType}');
        }
      case TypeOid.double:
        {
          if (input is double) {
            final bd = ByteData(8);
            bd.setFloat64(0, input);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: double Got: ${input.runtimeType}');
        }
      case TypeOid.date:
        {
          if (input is DateTime) {
            final bd = ByteData(4);
            bd.setInt32(0, input.toUtc().difference(DateTime.utc(2000)).inDays);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: DateTime Got: ${input.runtimeType}');
        }

      case TypeOid.time:
        {
          if (input is Time) {
            final bd = ByteData(8);
            bd.setInt64(0, input.microseconds);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: Time Got: ${input.runtimeType}');
        }

      case TypeOid.timestampWithoutTimezone:
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

      case TypeOid.timestampWithTimezone:
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

      case TypeOid.interval:
        {
          if (input is Interval) {
            final bd = ByteData(16);
            bd.setInt64(0, input.microseconds);
            bd.setInt32(8, input.days);
            bd.setInt32(12, input.months);
            return bd.buffer.asUint8List();
          }
          if (input is Duration) {
            final bd = ByteData(16);
            bd.setInt64(0, input.inMicroseconds);
            // ignoring the second 8 bytes
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: Interval Got: ${input.runtimeType}');
        }

      case TypeOid.numeric:
        {
          Object? source = input;

          if (source is double || source is int) {
            source = input.toString();
          }
          if (source is String) {
            return _encodeNumeric(source, encoding);
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: String|double|int Got: ${input.runtimeType}');
        }

      case TypeOid.jsonb:
        {
          final jsonBytes = _jsonFusedEncoding(encoding).encode(input);
          final writer = PgByteDataWriter(
              bufferLength: jsonBytes.length + 1, encoding: encoding);
          writer.writeUint8(1);
          writer.write(jsonBytes);
          return writer.toBytes();
        }

      case TypeOid.json:
        return castBytes(_jsonFusedEncoding(encoding).encode(input));

      case TypeOid.byteArray:
        {
          if (input is List<int>) {
            return castBytes(input);
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<int> Got: ${input.runtimeType}');
        }

      case TypeOid.uuid:
        {
          if (input is! String) {
            throw FormatException(
                'Invalid type for parameter value. Expected: String Got: ${input.runtimeType}');
          }
          return _encodeUuid(input);
        }

      case TypeOid.uuidArray:
        {
          if (input is List) {
            return _writeListBytes<String>(
              _castOrThrowList<String>(input),
              TypeOid.uuid,
              (_) => 16,
              (writer, item) => writer.write(_encodeUuid(item)),
              encoding,
            );
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<String> Got: ${input.runtimeType}');
        }

      case TypeOid.point:
        {
          if (input is Point) {
            final bd = ByteData(16);
            bd.setFloat64(0, input.latitude);
            bd.setFloat64(8, input.longitude);
            return bd.buffer.asUint8List();
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: Point Got: ${input.runtimeType}');
        }

      case TypeOid.line:
        if (input is Line) {
          final bd = ByteData(24);
          bd.setFloat64(0, input.a);
          bd.setFloat64(8, input.b);
          bd.setFloat64(16, input.c);
          return bd.buffer.asUint8List();
        }
        throw FormatException(
            'Invalid type for parameter value. Expected: Line Got: ${input.runtimeType}');

      case TypeOid.lineSegment:
        if (input is LineSegment) {
          final bd = ByteData(32);
          bd.setFloat64(0, input.p1.latitude);
          bd.setFloat64(8, input.p1.longitude);
          bd.setFloat64(16, input.p2.latitude);
          bd.setFloat64(24, input.p2.longitude);
          return bd.buffer.asUint8List();
        }
        throw FormatException(
            'Invalid type for parameter value. Expected: LineSegment Got: ${input.runtimeType}');

      case TypeOid.box:
        if (input is Box) {
          final bd = ByteData(32);
          bd.setFloat64(0, input.p1.latitude);
          bd.setFloat64(8, input.p1.longitude);
          bd.setFloat64(16, input.p2.latitude);
          bd.setFloat64(24, input.p2.longitude);
          return bd.buffer.asUint8List();
        }
        throw FormatException(
            'Invalid type for parameter value. Expected: Box Got: ${input.runtimeType}');

      case TypeOid.path:
        if (input is Path) {
          final bd = ByteData(5 + 16 * input.points.length);
          bd.setInt8(0, input.open ? 0 : 1);
          bd.setInt32(1, input.points.length);
          for (int i = 0; i < input.points.length; i++) {
            bd.setFloat64(i * 16 + 5, input.points[i].latitude);
            bd.setFloat64(i * 16 + 13, input.points[i].longitude);
          }
          return bd.buffer.asUint8List();
        }
        throw FormatException(
            'Invalid type for parameter value. Expected: Path Got: ${input.runtimeType}');

      case TypeOid.polygon:
        if (input is Polygon) {
          final bd = ByteData(4 + 16 * input.points.length);
          bd.setInt32(0, input.points.length);
          for (int i = 0; i < input.points.length; i++) {
            bd.setFloat64(i * 16 + 4, input.points[i].latitude);
            bd.setFloat64(i * 16 + 12, input.points[i].longitude);
          }
          return bd.buffer.asUint8List();
        }
        throw FormatException(
            'Invalid type for parameter value. Expected: Polygon Got: ${input.runtimeType}');

      case TypeOid.circle:
        if (input is Circle) {
          final bd = ByteData(24);
          bd.setFloat64(0, input.center.latitude);
          bd.setFloat64(8, input.center.longitude);
          bd.setFloat64(16, input.radius);
          return bd.buffer.asUint8List();
        }
        throw FormatException(
            'Invalid type for parameter value. Expected: Circle Got: ${input.runtimeType}');

      case TypeOid.regtype:
        final oid = input is Type ? input.oid : (input is int ? input : null);
        if (oid == null) {
          throw FormatException(
              'Invalid type for parameter value, expected a data type an int or Type, got $input');
        }

        final outBuffer = Uint8List(4);
        outBuffer.buffer.asByteData().setInt32(0, oid);
        return outBuffer;
      case TypeOid.booleanArray:
        {
          if (input is List) {
            return _writeListBytes<bool>(
              _castOrThrowList<bool>(input),
              16,
              (_) => 1,
              (writer, item) => writer.writeUint8(item ? 1 : 0),
              encoding,
            );
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<bool> Got: ${input.runtimeType}');
        }

      case TypeOid.smallIntegerArray:
        {
          if (input is List) {
            return _writeListBytes<int>(
              _castOrThrowList<int>(input),
              TypeOid.smallInteger,
              (_) => 2,
              (writer, item) => writer.writeInt16(item),
              encoding,
            );
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<int> Got: ${input.runtimeType}');
        }

      case TypeOid.integerArray:
        {
          if (input is List) {
            return _writeListBytes<int>(
              _castOrThrowList<int>(input),
              23,
              (_) => 4,
              (writer, item) => writer.writeInt32(item),
              encoding,
            );
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<int> Got: ${input.runtimeType}');
        }

      case TypeOid.bigIntegerArray:
        {
          if (input is List) {
            return _writeListBytes<int>(
              _castOrThrowList<int>(input),
              20,
              (_) => 8,
              (writer, item) => writer.writeInt64(item),
              encoding,
            );
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<int> Got: ${input.runtimeType}');
        }

      case TypeOid.dateArray:
        {
          if (input is List) {
            return _writeListBytes<DateTime>(
              _castOrThrowList<DateTime>(input),
              TypeOid.date,
              (_) => 4,
              (writer, item) => writer.writeInt32(
                  item.toUtc().difference(DateTime.utc(2000)).inDays),
              encoding,
            );
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<DateTime> Got: ${input.runtimeType}');
        }

      case TypeOid.timeArray:
        {
          if (input is List) {
            return _writeListBytes<Time>(
              _castOrThrowList<Time>(input),
              TypeOid.time,
              (_) => 8,
              (writer, item) => writer.writeInt64(item.microseconds),
              encoding,
            );
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<Time> Got: ${input.runtimeType}');
        }

      case TypeOid.timestampArray:
        {
          if (input is List) {
            return _writeListBytes<DateTime>(
              _castOrThrowList<DateTime>(input),
              TypeOid.timestamp,
              (_) => 8,
              (writer, item) => writer.writeInt64(
                  item.toUtc().difference(DateTime.utc(2000)).inMicroseconds),
              encoding,
            );
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<DateTime> Got: ${input.runtimeType}');
        }

      case TypeOid.timestampTzArray:
        {
          if (input is List) {
            return _writeListBytes<DateTime>(
              _castOrThrowList<DateTime>(input),
              TypeOid.timestampTz,
              (_) => 8,
              (writer, item) => writer.writeInt64(
                  item.toUtc().difference(DateTime.utc(2000)).inMicroseconds),
              encoding,
            );
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<DateTime> Got: ${input.runtimeType}');
        }

      case TypeOid.varCharArray:
        {
          if (input is List) {
            final bytesArray =
                _castOrThrowList<String>(input).map((v) => encoding.encode(v));
            return _writeListBytes<List<int>>(
              bytesArray,
              1043,
              (item) => item.length,
              (writer, item) => writer.write(item),
              encoding,
            );
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<String> Got: ${input.runtimeType}');
        }

      case TypeOid.textArray:
        {
          if (input is List) {
            final bytesArray =
                _castOrThrowList<String>(input).map((v) => encoding.encode(v));
            return _writeListBytes<List<int>>(
              bytesArray,
              25,
              (item) => item.length,
              (writer, item) => writer.write(item),
              encoding,
            );
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<String> Got: ${input.runtimeType}');
        }

      case TypeOid.doubleArray:
        {
          if (input is List) {
            return _writeListBytes<double>(
              _castOrThrowList<double>(input),
              701,
              (_) => 8,
              (writer, item) => writer.writeFloat64(item),
              encoding,
            );
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List<double> Got: ${input.runtimeType}');
        }

      case TypeOid.jsonbArray:
        {
          if (input is List) {
            final objectsArray = input.map(_jsonFusedEncoding(encoding).encode);
            return _writeListBytes<List<int>>(
              objectsArray,
              3802,
              (item) => item.length + 1,
              (writer, item) {
                writer.writeUint8(1);
                writer.write(item);
              },
              encoding,
            );
          }
          throw FormatException(
              'Invalid type for parameter value. Expected: List Got: ${input.runtimeType}');
        }

      case TypeOid.integerRange:
        if (input is IntRange) {
          return _encodeRange(input, encoding, Type.integer.oid!);
        }
        throw FormatException(
            'Invalid type for parameter value. Expected: IntRange Got: ${input.runtimeType}');

      case TypeOid.bigIntegerRange:
        if (input is IntRange) {
          return _encodeRange(input, encoding, Type.bigInteger.oid!);
        }
        throw FormatException(
            'Invalid type for parameter value. Expected: IntRange Got: ${input.runtimeType}');

      case TypeOid.dateRange:
        if (input is DateRange) {
          return _encodeRange(input, encoding, Type.date.oid!);
        }
        throw FormatException(
            'Invalid type for parameter value. Expected: DateRange Got: ${input.runtimeType}');

      case TypeOid.timestampRange:
        if (input is DateTimeRange) {
          return _encodeRange(
              input, encoding, Type.timestampWithoutTimezone.oid!);
        }
        throw FormatException(
            'Invalid type for parameter value. Expected: DateTimeRange Got: ${input.runtimeType}');

      case TypeOid.timestampTzRange:
        if (input is DateTimeRange) {
          return _encodeRange(input, encoding, Type.timestampWithTimezone.oid!);
        }
        throw FormatException(
            'Invalid type for parameter value. Expected: DateTimeRange Got: ${input.runtimeType}');
    }
    // Pass-through of Uint8List instances allows client with custom types to
    // encode their types for efficient binary transport.
    if (input is Uint8List) {
      return input;
    }
    throw ArgumentError('Cannot encode `$input` into oid($_typeOid).');
  }

  List<V> _castOrThrowList<V>(List input) {
    if (input is List<V>) {
      return input;
    }
    if (input.any((e) => e is! V)) {
      throw FormatException(
          'Invalid type for parameter value. Expected: List<${V.runtimeType}> Got: ${input.runtimeType}');
    }
    return input.cast<V>();
  }

  Uint8List _writeListBytes<V>(
    Iterable<V> value,
    int type,
    int Function(V item) lengthEncoder,
    void Function(PgByteDataWriter writer, V item) valueEncoder,
    Encoding encoding,
  ) {
    final writer = PgByteDataWriter(encoding: encoding);

    writer.writeInt32(1); // dimension
    writer.writeInt32(0); // ign
    writer.writeInt32(type); // type
    writer.writeInt32(value.length); // size
    writer.writeInt32(1); // index

    for (final i in value) {
      final len = lengthEncoder(i);
      writer.writeInt32(len);
      valueEncoder(writer, i);
    }

    return writer.toBytes();
  }

  /// Encode String / double / int to numeric / decimal  without loosing precision.
  /// Compare implementation: https://github.com/frohoff/jdk8u-dev-jdk/blob/da0da73ab82ed714dc5be94acd2f0d00fbdfe2e9/src/share/classes/java/math/BigDecimal.java#L409
  Uint8List _encodeNumeric(String value, Encoding encoding) {
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

    final writer = PgByteDataWriter(encoding: encoding);
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

  Uint8List _encodeRange<T>(
      Range<T> range, Encoding encoding, int elementTypeOid) {
    final buffer = BytesBuffer();
    buffer.add([range.flag]);
    switch ((range.lower == null, range.upper == null)) {
      case (false, false):
        if (range.flag == 1) break;
        _encodeRangeValue(range.lower, encoding, elementTypeOid, buffer);
        _encodeRangeValue(range.upper, encoding, elementTypeOid, buffer);
        break;
      case (false, true) || (true, false):
        final value = range.lower ?? range.upper!;
        _encodeRangeValue(value, encoding, elementTypeOid, buffer);
        break;
      case (true, true):
        break;
    }
    return buffer.toBytes();
  }

  // Adds 4 length bytes followed by the value bytes
  _encodeRangeValue<T>(
      T value, Encoding encoding, int elementTypeOid, BytesBuffer buffer) {
    final encoder = PostgresBinaryEncoder(elementTypeOid);
    final valueBytes = encoder.convert(value as Object, encoding);
    final lengthBytes = ByteData(4)..setInt32(0, valueBytes.length);
    buffer.add(lengthBytes.buffer.asUint8List());
    buffer.add(valueBytes);
  }

  Uint8List _encodeUuid(String value) {
    final hexBytes =
        value.toLowerCase().codeUnits.where((c) => c != _dashUnit).toList();
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
}

class PostgresBinaryDecoder {
  final int typeOid;

  PostgresBinaryDecoder(this.typeOid);

  Object? convert(DecodeInput dinput) {
    final encoding = dinput.encoding;

    final input = dinput.bytes;
    late final buffer =
        ByteData.view(input.buffer, input.offsetInBytes, input.lengthInBytes);

    switch (typeOid) {
      case TypeOid.character:
      case TypeOid.name:
      case TypeOid.text:
      case TypeOid.varChar:
        return encoding.decode(input);
      case TypeOid.boolean:
        return (buffer.getInt8(0) != 0);
      case TypeOid.smallInteger:
        return buffer.getInt16(0);
      case TypeOid.integer:
        return buffer.getInt32(0);
      case TypeOid.bigInteger:
        return buffer.getInt64(0);
      case TypeOid.real:
        return buffer.getFloat32(0);
      case TypeOid.double:
        return buffer.getFloat64(0);
      case TypeOid.time:
        return Time.fromMicroseconds(buffer.getInt64(0));
      case TypeOid.date:
        final value = buffer.getInt32(0);
        //infinity || -infinity
        if (value == 2147483647 || value == -2147483648) {
          return null;
        }
        if (dinput.timeZone.forceDecodeDateAsUTC) {
          return DateTime.utc(2000).add(Duration(days: value));
        }
        return DateTime(2000).add(Duration(days: value));
      case TypeOid.timestampWithoutTimezone:
        final value = buffer.getInt64(0);
        //infinity || -infinity
        if (value == 9223372036854775807 || value == -9223372036854775808) {
          return null;
        }

        if (dinput.timeZone.forceDecodeTimestampAsUTC) {
          return DateTime.utc(2000).add(Duration(microseconds: value));
        }
        return DateTime(2000).add(Duration(microseconds: value));

      case TypeOid.timestampWithTimezone:
        final value = buffer.getInt64(0);

        //infinity || -infinity
        if (value == 9223372036854775807 || value == -9223372036854775808) {
          return null;
        }

        var datetime = DateTime.utc(2000).add(Duration(microseconds: value));
        if (dinput.timeZone.value.toLowerCase() == 'utc') {
          return datetime;
        }
        if (dinput.timeZone.forceDecodeTimestamptzAsUTC) {
          return datetime;
        }

        final pgTimeZone = dinput.timeZone.value.toLowerCase();
        final tzLocations = tz.timeZoneDatabase.locations.entries
            .where((e) {
              return e.key.toLowerCase() == pgTimeZone ||
                  e.value.currentTimeZone.abbreviation.toLowerCase() ==
                      pgTimeZone;
            })
            .map((e) => e.value)
            .toList();

        if (tzLocations.isEmpty) {
          throw tz.LocationNotFoundException(
              'Location with the name "$pgTimeZone" doesn\'t exist');
        }
        final tzLocation = tzLocations.first;
        //define location for TZDateTime.toLocal()
        tzenv.setLocalLocation(tzLocation);

        final offsetInMilliseconds = tzLocation.currentTimeZone.offset;
        // Conversion of milliseconds to hours
        final double offset = offsetInMilliseconds / (1000 * 60 * 60);

        if (offset < 0) {
          final subtr = Duration(
              hours: offset.abs().truncate(),
              minutes: ((offset.abs() % 1) * 60).round());
          datetime = datetime.subtract(subtr);
          final specificDate = tz.TZDateTime(
              tzLocation,
              datetime.year,
              datetime.month,
              datetime.day,
              datetime.hour,
              datetime.minute,
              datetime.second,
              datetime.millisecond,
              datetime.microsecond);
          return specificDate;
        } else if (offset > 0) {
          final addr = Duration(
              hours: offset.truncate(), minutes: ((offset % 1) * 60).round());
          datetime = datetime.add(addr);
          final specificDate = tz.TZDateTime(
              tzLocation,
              datetime.year,
              datetime.month,
              datetime.day,
              datetime.hour,
              datetime.minute,
              datetime.second,
              datetime.millisecond,
              datetime.microsecond);
          return specificDate;
        }

        return datetime;

      case TypeOid.interval:
        return Interval(
          microseconds: buffer.getInt64(0),
          days: buffer.getInt32(8),
          months: buffer.getInt32(12),
        );

      case TypeOid.numeric:
        return _decodeNumeric(input);

      case TypeOid.jsonb:
        {
          // Removes version which is first character and currently always '1'
          final bytes = input.buffer
              .asUint8List(input.offsetInBytes + 1, input.lengthInBytes - 1);
          return _jsonFusedEncoding(encoding).decode(bytes);
        }

      case TypeOid.json:
        return _jsonFusedEncoding(encoding).decode(input);

      case TypeOid.byteArray:
        return input;

      case TypeOid.uuid:
        return _decodeUuid(input);
      case TypeOid.uuidArray:
        return readListBytes<String>(
            input, (reader, _) => _decodeUuid(reader.read(16)));

      case TypeOid.regtype:
        final data = input.buffer.asByteData(input.offsetInBytes, input.length);
        final oid = data.getInt32(0);
        return dinput.typeRegistry.resolveOid(oid);
      case TypeOid.voidType:
        return null;

      case TypeOid.point:
        return Point(buffer.getFloat64(0), buffer.getFloat64(8));

      case TypeOid.line:
        return Line(
            buffer.getFloat64(0), buffer.getFloat64(8), buffer.getFloat64(16));

      case TypeOid.lineSegment:
        return LineSegment(Point(buffer.getFloat64(0), buffer.getFloat64(8)),
            Point(buffer.getFloat64(16), buffer.getFloat64(24)));

      case TypeOid.box:
        return Box(Point(buffer.getFloat64(0), buffer.getFloat64(8)),
            Point(buffer.getFloat64(16), buffer.getFloat64(24)));

      case TypeOid.path:
        final open = buffer.getInt8(0) == 0;
        final length = buffer.getInt32(1);
        final points = <Point>[];
        for (int i = 0; i < length; i++) {
          final x = buffer.getFloat64(i * 16 + 5);
          final y = buffer.getFloat64(i * 16 + 13);
          points.add(Point(x, y));
        }
        return Path(points, open: open);

      case TypeOid.polygon:
        final length = buffer.getInt32(0);
        final points = <Point>[];
        for (int i = 0; i < length; i++) {
          final x = buffer.getFloat64(i * 16 + 4);
          final y = buffer.getFloat64(i * 16 + 12);
          points.add(Point(x, y));
        }
        return Polygon(points);

      case TypeOid.circle:
        return Circle(Point(buffer.getFloat64(0), buffer.getFloat64(8)),
            buffer.getFloat64(16));

      case TypeOid.booleanArray:
        return readListBytes<bool>(
            input, (reader, _) => reader.readUint8() != 0);

      case TypeOid.smallIntegerArray:
        return readListBytes<int>(input, (reader, _) => reader.readInt16());
      case TypeOid.integerArray:
        return readListBytes<int>(input, (reader, _) => reader.readInt32());
      case TypeOid.bigIntegerArray:
        return readListBytes<int>(input, (reader, _) => reader.readInt64());

      case TypeOid.dateArray:
        return readListBytes<DateTime>(
            input,
            (reader, _) =>
                DateTime.utc(2000).add(Duration(days: reader.readInt32())));
      case TypeOid.timeArray:
        return readListBytes<Time>(
            input, (reader, _) => Time.fromMicroseconds(reader.readInt64()));
      case TypeOid.timestampArray:
      case TypeOid.timestampTzArray:
        return readListBytes<DateTime>(
            input,
            (reader, _) => DateTime.utc(2000)
                .add(Duration(microseconds: reader.readInt64())));

      case TypeOid.varCharArray:
      case TypeOid.textArray:
        return readListBytes<String>(input, (reader, length) {
          return encoding.decode(length > 0 ? reader.read(length) : []);
        });

      case TypeOid.doubleArray:
        return readListBytes<double>(
            input, (reader, _) => reader.readFloat64());

      case TypeOid.jsonbArray:
        return readListBytes<dynamic>(input, (reader, length) {
          reader.read(1);
          final bytes = reader.read(length - 1);
          return _jsonFusedEncoding(encoding).decode(bytes);
        });

      case TypeOid.integerRange:
        final range = _decodeRange(buffer, dinput, Type.integer.oid!);
        return range == null
            ? IntRange.empty()
            : IntRange(range.$1, range.$2, range.$3);
      case TypeOid.bigIntegerRange:
        final range = _decodeRange(buffer, dinput, Type.bigInteger.oid!);
        return range == null
            ? IntRange.empty()
            : IntRange(range.$1, range.$2, range.$3);
      case TypeOid.dateRange:
        final range = _decodeRange(buffer, dinput, Type.date.oid!);
        return range == null
            ? DateRange.empty()
            : DateRange(range.$1, range.$2, range.$3);
      case TypeOid.timestampRange:
        final range =
            _decodeRange(buffer, dinput, Type.timestampWithoutTimezone.oid!);
        return range == null
            ? DateTimeRange.empty()
            : DateTimeRange(range.$1, range.$2, range.$3);
      case TypeOid.timestampTzRange:
        final range =
            _decodeRange(buffer, dinput, Type.timestampWithTimezone.oid!);
        return range == null
            ? DateTimeRange.empty()
            : DateTimeRange(range.$1, range.$2, range.$3);
    }
    return UndecodedBytes(
      typeOid: typeOid,
      bytes: input,
      isBinary: true,
      encoding: encoding,
    );
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

  (T?, T?, Bounds)? _decodeRange<T>(
      ByteData buffer, DecodeInput dinput, int elementTypeOid) {
    final flag = buffer.getInt8(0);
    final bounds = Bounds.fromFlag(flag);
    switch (flag) {
      case 0 || 2 || 4 || 6:
        final lowerLength = buffer.getInt32(1);
        final lowerBytes = dinput.bytes.sublist(5, 5 + lowerLength);
        final lower = _decodeRangeElement(dinput, elementTypeOid, lowerBytes);
        final upperBytes = dinput.bytes.sublist(9 + lowerLength);
        final upper = _decodeRangeElement(dinput, elementTypeOid, upperBytes);
        return (lower, upper, bounds);
      case 8 || 12:
        final bytes = dinput.bytes.sublist(5);
        final upper = _decodeRangeElement(dinput, elementTypeOid, bytes);
        return (null, upper, bounds);
      case 16 || 18:
        final bytes = dinput.bytes.sublist(5);
        final lower = _decodeRangeElement(dinput, elementTypeOid, bytes);
        return (lower, null, bounds);
      case 24:
        return (null, null, bounds);
      default:
        return null;
    }
  }

  T _decodeRangeElement<T>(
      DecodeInput dinput, int elementTypeOid, Uint8List bytes) {
    final decoder = PostgresBinaryDecoder(elementTypeOid);
    return decoder.convert(DecodeInput(
        bytes: bytes,
        isBinary: dinput.isBinary,
        encoding: dinput.encoding,
        timeZone: dinput.timeZone,
        typeRegistry: dinput.typeRegistry)) as T;
  }

  String _decodeUuid(Uint8List bytes) {
    late final buffer =
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);
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
}
