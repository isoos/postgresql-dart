import 'dart:core';
import 'dart:core' as core;

import 'models.dart';

/*
  Adding a new type:

  1. add item to this enumeration
  2. update all switch statements on this type
  3. add pg type code -> enumeration item in PostgresBinaryDecoder.typeMap
     (lookup type code: https://doxygen.postgresql.org/pg__type_8h_source.html)
  4. add identifying key to PostgreSQLFormatIdentifier.typeStringToCodeMap.
  5. add identifying key to PostgreSQLFormat.dataTypeStringForDataType
 */

/// Supported data types.
enum PostgreSQLDataType<Dart extends Object> {
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

  const PostgreSQLDataType(this.oid);

  static final Map<int, PostgreSQLDataType> byTypeOid = Map.unmodifiable({
    for (final type in values)
      if (type.oid != null) type.oid!: type,
  });
}

/// LSN is a PostgreSQL Log Sequence Number.
///
/// For more details, see: https://www.postgresql.org/docs/current/datatype-pg-lsn.html
class LSN {
  final int value;

  /// Construct an LSN from a 64-bit integer.
  LSN(this.value);

  /// Construct an LSN from XXX/XXX format used by PostgreSQL
  LSN.fromString(String string) : value = _parseLSNString(string);

  /// Formats the LSN value into the XXX/XXX format which is the text format
  /// used by PostgreSQL.
  @override
  String toString() {
    return '${(value >> 32).toRadixString(16).toUpperCase()}/${value.toUnsigned(32).toRadixString(16).toUpperCase()}';
  }

  static int _parseLSNString(String string) {
    final halves = string.split('/');
    if (halves.length != 2) {
      throw FormatException('Invalid LSN String was given ($string)');
    }
    final upperhalf = int.parse(halves[0], radix: 16) << 32;
    final lowerhalf = int.parse(halves[1], radix: 16);

    return (upperhalf + lowerhalf).toInt();
  }

  LSN operator +(LSN other) {
    return LSN(value + other.value);
  }

  LSN operator -(LSN other) {
    return LSN(value + other.value);
  }

  @override
  bool operator ==(covariant LSN other) {
    if (identical(this, other)) return true;

    return other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
