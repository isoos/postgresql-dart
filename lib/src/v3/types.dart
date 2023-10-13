import 'dart:core';
import 'dart:core' as core;

import 'package:meta/meta.dart';

/// Describes PostgreSQL's geometric type: `point`.
@immutable
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
  int get hashCode => Object.hash(latitude, longitude);
}

/// Supported data types.
enum PgDataType<Dart extends Object> {
  /// Used to represent a type not yet understood by this package.
  unknownType<Object>(null),

  /// Used to represent value without any type representation.
  unspecified<Object>(null),

  /// Must be a [String].
  text<String>(25, nameForSubstitution: 'text'),

  /// Must be an [int] (4-byte integer)
  integer<int>(23, nameForSubstitution: 'int4'),

  /// Must be an [int] (2-byte integer)
  smallInteger<int>(21, nameForSubstitution: 'int2'),

  /// Must be an [int] (8-byte integer)
  bigInteger<int>(20, nameForSubstitution: 'int8'),

  /// Must be an [int] (autoincrementing 4-byte integer)
  serial(null, nameForSubstitution: 'int4'),

  /// Must be an [int] (autoincrementing 8-byte integer)
  bigSerial(null, nameForSubstitution: 'int8'),

  /// Must be a [double] (32-bit floating point value)
  real<core.double>(700, nameForSubstitution: 'float4'),

  /// Must be a [double] (64-bit floating point value)
  double<core.double>(701, nameForSubstitution: 'float8'),

  /// Must be a [bool]
  boolean<bool>(16, nameForSubstitution: 'boolean'),

  /// Must be a [DateTime] (microsecond date and time precision)
  timestampWithoutTimezone<DateTime>(1114, nameForSubstitution: 'timestamp'),

  /// Must be a [DateTime] (microsecond date and time precision)
  timestampWithTimezone<DateTime>(1184, nameForSubstitution: 'timestamptz'),

  /// Must be a [Duration]
  interval<Duration>(1186, nameForSubstitution: 'interval'),

  /// An arbitrary-precision number.
  ///
  /// This library supports encoding numbers in a textual format, or when
  /// passed as [int] or [double]. When decoding values, numeric types are
  /// always returned as string.
  numeric<Object>(1700, nameForSubstitution: 'numeric'),

  /// Must be a [DateTime] (contains year, month and day only)
  date<DateTime>(1082, nameForSubstitution: 'date'),

  /// Must be encodable via [json.encode].
  ///
  /// Values will be encoded via [json.encode] before being sent to the database.
  jsonb(3802, nameForSubstitution: 'jsonb'),

  /// Must be encodable via [core.json.encode].
  ///
  /// Values will be encoded via [core.json.encode] before being sent to the database.
  json(114, nameForSubstitution: 'json'),

  /// Must be a [List] of [int].
  ///
  /// Each element of the list must fit into a byte (0-255).
  byteArray<List<int>>(17, nameForSubstitution: 'bytea'),

  /// Must be a [String]
  ///
  /// Used for internal pg structure names
  name<String>(19, nameForSubstitution: 'name'),

  /// Must be a [String].
  ///
  /// Must contain 32 hexadecimal characters. May contain any number of '-' characters.
  /// When returned from database, format will be xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.
  uuid<String>(2950, nameForSubstitution: 'uuid'),

  /// Must be a [PgPoint]
  point<PgPoint>(600, nameForSubstitution: 'point'),

  /// Must be a [List<bool>]
  booleanArray<List<bool>>(1000, nameForSubstitution: '_bool'),

  /// Must be a [List<int>]
  integerArray<List<int>>(1007, nameForSubstitution: '_int4'),

  /// Must be a [List<int>]
  bigIntegerArray<List<int>>(1016, nameForSubstitution: '_int8'),

  /// Must be a [List<String>]
  textArray<List<String>>(1009, nameForSubstitution: '_text'),

  /// Must be a [List<double>]
  doubleArray<List<core.double>>(1022, nameForSubstitution: '_float8'),

  /// Must be a [String]
  varChar<String>(1043, nameForSubstitution: 'varchar'),

  /// Must be a [List<String>]
  varCharArray<List<String>>(1015, nameForSubstitution: '_varchar'),

  /// Must be a [List] of encodable objects
  jsonbArray<List>(3807, nameForSubstitution: '_jsonb'),

  /// Must be a [PgDataType].
  regtype<PgDataType>(2206, nameForSubstitution: 'regtype'),

  /// Impossible to bind to, always null when read.
  voidType<Object>(2278),
  ;

  /// The object ID of this data type.
  final int? oid;

  /// The name of this type as considered by [PgSql.map].
  ///
  /// To declare an explicit type for a substituted parameter in a query, this
  /// name can be used.
  final String? nameForSubstitution;

  const PgDataType(this.oid, {this.nameForSubstitution});

  static final Map<int, PgDataType> byTypeOid = Map.unmodifiable({
    for (final type in values)
      if (type.oid != null) type.oid: type,
  });

  static final Map<String, PgDataType> bySubstitutionName = Map.unmodifiable({
    for (final type in values)
      // We don't index serial and bigSerial types here because they're using
      // the same names as int4 and int8, respectively.
      // However, when a user is referring to these types in a query, they
      // should always resolve to integer and bigInteger.
      if (type != serial &&
          type != bigSerial &&
          type.nameForSubstitution != null)
        type.nameForSubstitution: type,
  });
}
