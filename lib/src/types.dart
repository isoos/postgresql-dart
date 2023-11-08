import 'dart:convert';
import 'dart:core';
import 'dart:core' as core;
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'types/generic_type.dart';
import 'types/type_registry.dart';

/// In Postgresql `interval` values are stored as [months], [days], and [microseconds].
/// This is done because the number of days in a month varies, and a day can
/// have 23 or 25 hours if a daylight savings time adjustment is involved.
///
/// Value from one field is never automatically translated to value of
/// another field, so <60*60*24 seconds> != <1 days> and so on.
@immutable
class Interval {
  final int months;
  final int days;
  final int microseconds;

  Interval({
    this.months = 0,
    this.days = 0,
    this.microseconds = 0,
  });

  factory Interval.duration(Duration value) =>
      Interval(microseconds: value.inMicroseconds);

  late final _asStringParts = [
    if (months != 0) '$months months',
    if (days != 0) '$days days',
    if (microseconds != 0) '$microseconds microseconds',
  ];
  late final _asString =
      _asStringParts.isEmpty ? '0 microseconds' : _asStringParts.join(' ');

  @override
  String toString() => _asString;

  @override
  int get hashCode => Object.hashAll([months, days, microseconds]);

  @override
  bool operator ==(Object other) {
    return other is Interval &&
        other.months == months &&
        other.days == days &&
        other.microseconds == microseconds;
  }
}

/// Describes a generic bytes string value..
@immutable
class TypedBytes {
  final int typeOid;
  final Uint8List bytes;

  TypedBytes({
    required this.typeOid,
    required this.bytes,
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

    return upperhalf + lowerhalf;
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

/// Describes PostgreSQL's geometric type: `point`.
@immutable
class Point {
  /// also referred as `x`
  final double latitude;

  /// also referred as `y`
  final double longitude;

  const Point(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// Supported data types.
abstract class Type<T extends Object> {
  /// Used to represent value without any type representation.
  static const unspecified = GenericType<Object>(null);

  /// Must be a [String].
  static const text =
      GenericType<String>(TypeOid.text, nameForSubstitution: 'text');

  /// Must be an [int] (4-byte integer)
  static const integer =
      GenericType<int>(TypeOid.integer, nameForSubstitution: 'int4');

  /// Must be an [int] (2-byte integer)
  static const smallInteger =
      GenericType<int>(TypeOid.smallInteger, nameForSubstitution: 'int2');

  /// Must be an [int] (8-byte integer)
  static const bigInteger =
      GenericType<int>(TypeOid.bigInteger, nameForSubstitution: 'int8');

  /// Must be an [int] (autoincrementing 4-byte integer)
  static const serial = GenericType<int>(null, nameForSubstitution: 'int4');

  /// Must be an [int] (autoincrementing 8-byte integer)
  static const bigSerial = GenericType<int>(null, nameForSubstitution: 'int8');

  /// Must be a [double] (32-bit floating point value)
  static const real =
      GenericType<core.double>(TypeOid.real, nameForSubstitution: 'float4');

  /// Must be a [double] (64-bit floating point value)
  static const double =
      GenericType<core.double>(TypeOid.double, nameForSubstitution: 'float8');

  /// Must be a [bool]
  static const boolean =
      GenericType<bool>(TypeOid.boolean, nameForSubstitution: 'boolean');

  /// Must be a [DateTime] (microsecond date and time precision)
  static const timestampWithoutTimezone = GenericType<DateTime>(
      TypeOid.timestampWithoutTimezone,
      nameForSubstitution: 'timestamp');

  /// Must be a [DateTime] (microsecond date and time precision)
  static const timestampWithTimezone = GenericType<DateTime>(
      TypeOid.timestampWithTimezone,
      nameForSubstitution: 'timestamptz');

  /// Must be a [Interval]
  static const interval =
      GenericType<Interval>(TypeOid.interval, nameForSubstitution: 'interval');

  /// An arbitrary-precision number.
  ///
  /// This library supports encoding numbers in a textual format, or when
  /// passed as [int] or [double]. When decoding values, numeric types are
  /// always returned as string.
  static const numeric =
      GenericType<Object>(TypeOid.numeric, nameForSubstitution: 'numeric');

  /// Must be a [DateTime] (contains year, month and day only)
  static const date =
      GenericType<DateTime>(TypeOid.date, nameForSubstitution: 'date');

  /// Must be encodable via [json.encode].
  ///
  /// Values will be encoded via [json.encode] before being sent to the database.
  static const jsonb = GenericType(TypeOid.jsonb, nameForSubstitution: 'jsonb');

  /// Must be encodable via [core.json.encode].
  ///
  /// Values will be encoded via [core.json.encode] before being sent to the database.
  static const json = GenericType(TypeOid.json, nameForSubstitution: 'json');

  /// Must be a [List] of [int].
  ///
  /// Each element of the list must fit into a byte (0-255).
  static const byteArray =
      GenericType<List<int>>(TypeOid.byteArray, nameForSubstitution: 'bytea');

  /// Must be a [String]
  ///
  /// Used for internal pg structure names
  static const name =
      GenericType<String>(TypeOid.name, nameForSubstitution: 'name');

  /// Must be a [String].
  ///
  /// Must contain 32 hexadecimal characters. May contain any number of '-' characters.
  /// When returned from database, format will be xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.
  static const uuid =
      GenericType<String>(TypeOid.uuid, nameForSubstitution: 'uuid');

  /// Must be a [Point]
  static const point =
      GenericType<Point>(TypeOid.point, nameForSubstitution: 'point');

  /// Must be a [List<bool>]
  static const booleanArray = GenericType<List<bool>>(TypeOid.booleanArray,
      nameForSubstitution: '_bool');

  /// Must be a [List<int>]
  static const integerArray = GenericType<List<int>>(TypeOid.integerArray,
      nameForSubstitution: '_int4');

  /// Must be a [List<int>]
  static const bigIntegerArray = GenericType<List<int>>(TypeOid.bigIntegerArray,
      nameForSubstitution: '_int8');

  /// Must be a [List<String>]
  static const textArray = GenericType<List<String>>(TypeOid.textArray,
      nameForSubstitution: '_text');

  /// Must be a [List<double>]
  static const doubleArray = GenericType<List<core.double>>(TypeOid.doubleArray,
      nameForSubstitution: '_float8');

  /// Must be a [String]
  static const varChar =
      GenericType<String>(TypeOid.varChar, nameForSubstitution: 'varchar');

  /// Must be a [List<String>]
  static const varCharArray = GenericType<List<String>>(TypeOid.varCharArray,
      nameForSubstitution: '_varchar');

  /// Must be a [List] of encodable objects
  static const jsonbArray =
      GenericType<List>(TypeOid.jsonbArray, nameForSubstitution: '_jsonb');

  /// Must be a [Type].
  static const regtype =
      GenericType<Type>(TypeOid.regtype, nameForSubstitution: 'regtype');

  /// Impossible to bind to, always null when read.
  static const voidType = GenericType<Object>(TypeOid.voidType);

  /// The object ID of this data type.
  final int? oid;

  /// The name of this type as considered by [Sql.named].
  ///
  /// To declare an explicit type for a substituted parameter in a query, this
  /// name can be used.
  final String? nameForSubstitution;

  final String _name;

  const Type(
    this.oid, {
    this.nameForSubstitution,
    String? name,
  }) : _name = name ?? 'type($oid)';

  String get name_ => _name;
  bool get hasOid => oid != null && oid! > 0;

  TypedValue<T> value(T value) => TypedValue<T>(this, value);

  EncodeOutput encode(EncodeInput input);

  Object? decode(DecodeInput input);
}

class EncodeInput {
  final Object value;
  final Encoding encoding;

  EncodeInput({
    required this.value,
    required this.encoding,
  });
}

class EncodeOutput {
  final Uint8List? bytes;
  final String? text;

  EncodeOutput.bytes(Uint8List value)
      : bytes = value,
        text = null;

  EncodeOutput.text(String value)
      : bytes = null,
        text = value;

  bool get isBinary => bytes != null;
}

class DecodeInput {
  final Uint8List bytes;
  final bool isBinary;
  final Encoding encoding;

  DecodeInput({
    required this.bytes,
    required this.isBinary,
    required this.encoding,
  });

  late final asText = encoding.decode(bytes);
}

class TypedValue<T extends Object> {
  final Type<T> type;
  final T? value;

  TypedValue(this.type, this.value);

  @override
  int get hashCode => Object.hash(type, value);

  @override
  bool operator ==(Object other) {
    return other is TypedValue && other.type == type && other.value == value;
  }

  @override
  String toString() {
    return 'TypedValue($type, $value)';
  }
}
