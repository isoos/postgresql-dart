import 'dart:convert';
import 'dart:core';
import 'dart:core' as core;
import 'dart:typed_data';

import '../binary_codec.dart';

/// Describes PostgreSQL's geometric type: `point`.
class PgPoint {
  final double latitude;
  final double longitude;
  const PgPoint(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PgPoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Supported data types.
enum PgDataType<Dart extends Object> {
  /// Must be a [String].
  text<String>(25),

  /// Must be an [int] (4-byte integer)
  integer<int>(23),

  /// Must be an [int] (2-byte integer)
  smallInteger<int>(21),

  /// Must be an [int] (8-byte integer)
  bigInteger<int>(20),

  /// Must be an [int] (autoincrementing 4-byte integer)
  serial(null),

  /// Must be an [int] (autoincrementing 8-byte integer)
  bigSerial(null),

  /// Must be a [double] (32-bit floating point value)
  real<core.double>(700),

  /// Must be a [double] (64-bit floating point value)
  double<core.double>(701),

  /// Must be a [bool]
  boolean<bool>(16),

  /// Must be a [DateTime] (microsecond date and time precision)
  timestampWithoutTimezone<DateTime>(1114),

  /// Must be a [DateTime] (microsecond date and time precision)
  timestampWithTimezone<DateTime>(1184),

  /// Must be a [Duration]
  interval<Duration>(1186),

  /// Must be a [List<int>]
  numeric<List<int>>(1700),

  /// Must be a [DateTime] (contains year, month and day only)
  date<DateTime>(1082),

  /// Must be encodable via [json.encode].
  ///
  /// Values will be encoded via [json.encode] before being sent to the database.
  jsonb(3802),

  /// Must be encodable via [core.json.encode].
  ///
  /// Values will be encoded via [core.json.encode] before being sent to the database.
  json(114),

  /// Must be a [List] of [int].
  ///
  /// Each element of the list must fit into a byte (0-255).
  byteArray<List<int>>(17),

  /// Must be a [String]
  ///
  /// Used for internal pg structure names
  name<String>(19),

  /// Must be a [String].
  ///
  /// Must contain 32 hexadecimal characters. May contain any number of '-' characters.
  /// When returned from database, format will be xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.
  uuid<String>(2950),

  /// Must be a [PgPoint]
  point<PgPoint>(600),

  /// Must be a [List<bool>]
  booleanArray<List<bool>>(1000),

  /// Must be a [List<int>]
  integerArray<List<int>>(1007),

  /// Must be a [List<String>]
  textArray<List<String>>(1009),

  /// Must be a [List<double>]
  doubleArray<List<core.double>>(1022),

  /// Must be a [String]
  varChar<String>(1043),

  /// Must be a [List<String>]
  varCharArray<List<String>>(1015),

  /// Must be a [List] of encodable objects
  jsonbArray<List>(3807);

  /// The object ID of this data type.
  final int? oid;

  Codec<Dart?, Uint8List?> get codec {
    return _codecs.putIfAbsent(this, () => _TypeCodec<Dart>(this))
        as Codec<Dart?, Uint8List?>;
  }

  const PgDataType(this.oid);

  static final Map<int, PgDataType> byTypeOid = Map.unmodifiable({
    for (final type in values)
      if (type.oid != null) type.oid!: type,
  });

  static final Map<PgDataType, _TypeCodec> _codecs = {};
}

class _TypeCodec<D extends Object> extends Codec<D?, Uint8List?> {
  @override
  final Converter<D?, Uint8List?> encoder;
  @override
  final Converter<Uint8List?, D?> decoder;

  _TypeCodec(PgDataType<D> type)
      : encoder = PostgresBinaryEncoder(type),
        // Only some integer variants have no dedicated oid, they share it with
        // the normal integer.
        decoder = PostgresBinaryDecoder(type.oid ?? PgDataType.integer.oid!);
}
