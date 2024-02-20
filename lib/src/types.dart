import 'dart:convert';
import 'dart:core' as core;
import 'dart:core';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'types/generic_type.dart';
import 'types/geo_types.dart';
import 'types/range_types.dart';
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
class UndecodedBytes {
  final int typeOid;
  final bool isBinary;
  final Uint8List bytes;
  final Encoding encoding;

  UndecodedBytes({
    required this.typeOid,
    required this.isBinary,
    required this.bytes,
    required this.encoding,
  });

  late final asString = encoding.decode(bytes);
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

/// Describes PostgreSQL's `time without time zone` type.
///
/// See https://www.postgresql.org/docs/current/datatype-datetime.html
///
/// `time with time zone` is not implemented as Postgres wiki recommends against its use:
///
/// https://wiki.postgresql.org/wiki/Don't_Do_This#Don.27t_use_timetz
@immutable
@sealed
final class Time {
  /// The time in microseconds
  late final int microseconds;

  /// Construct a [Time] instance from [microseconds].
  ///
  /// [microseconds] must be positive and not resolve to a time larger than 24:00:00.000000.
  Time.fromMicroseconds(this.microseconds) {
    _check();
  }

  /// Construct a [Time] instance.
  ///
  /// [Time] value must be positive and not larger than 24:00:00.000000.
  factory Time([
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    return Time.fromMicroseconds(hour * Duration.microsecondsPerHour +
        minute * Duration.microsecondsPerMinute +
        second * Duration.microsecondsPerSecond +
        millisecond * Duration.microsecondsPerMillisecond +
        microsecond);
  }

  _check() {
    if (microseconds > Duration.microsecondsPerDay) {
      throw ArgumentError(
          'Time: values greater than 24:00:00.000000 are not allowed');
    }
    if (microseconds < 0) {
      throw ArgumentError('Time: negative value not allowed');
    }
  }

  DateTime get utcDateTime =>
      DateTime.fromMicrosecondsSinceEpoch(microseconds, isUtc: true);

  /// The hour of the day, expressed as in a 25-hour clock `0...24`.
  int get hour =>
      microseconds == Duration.microsecondsPerDay ? 24 : utcDateTime.hour;

  /// The minute `[0...59]`.
  int get minute => utcDateTime.minute;

  /// The second `[0...59]`.
  int get second => utcDateTime.second;

  /// The millisecond `[0...999]`.
  int get millisecond => utcDateTime.millisecond;

  /// The microsecond `[0...999]`.
  int get microsecond => utcDateTime.microsecond;

  @override
  String toString() => microseconds == Duration.microsecondsPerDay
      ? 'Time(24:00:00.000)'
      : 'Time(${utcDateTime.toIso8601String().split('T')[1].replaceAll('Z', '')})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Time && microseconds == other.microseconds;

  @override
  int get hashCode => microseconds;
}

/// Supported data types.
abstract class Type<T extends Object> {
  /// Used to represent value without any type representation.
  static const unspecified = UnspecifiedType();

  /// Must be a [String]
  static const character = GenericType<String>(TypeOid.character);

  /// Must be a [String].
  static const text = GenericType<String>(TypeOid.text);

  /// Must be an [int] (4-byte integer)
  static const integer = GenericType<int>(TypeOid.integer);

  /// Must be an [int] (2-byte integer)
  static const smallInteger = GenericType<int>(TypeOid.smallInteger);

  /// Must be an [int] (8-byte integer)
  static const bigInteger = GenericType<int>(TypeOid.bigInteger);

  /// Must be an [int] (autoincrementing 4-byte integer)
  static const serial = integer;

  /// Must be an [int] (autoincrementing 8-byte integer)
  static const bigSerial = bigInteger;

  /// Must be a [double] (32-bit floating point value)
  static const real = GenericType<core.double>(TypeOid.real);

  /// Must be a [double] (64-bit floating point value)
  static const double = GenericType<core.double>(TypeOid.double);

  /// Must be a [bool]
  static const boolean = GenericType<bool>(TypeOid.boolean);

  /// Must be a [Time]
  static const time = GenericType<Time>(TypeOid.time);

  /// Must be a [DateTime] (microsecond date and time precision)
  static const timestamp =
      GenericType<DateTime>(TypeOid.timestampWithoutTimezone);

  /// Please use [Type.timestamp] instead.
  static const timestampWithoutTimezone = timestamp;

  /// Must be a [DateTime] (microsecond date and time precision)
  static const timestampTz =
      GenericType<DateTime>(TypeOid.timestampWithTimezone);

  /// Please use [Type.timestampTz] instead.
  static const timestampWithTimezone = timestampTz;

  /// Must be a [Interval]
  static const interval = GenericType<Interval>(TypeOid.interval);

  /// An arbitrary-precision number.
  ///
  /// This library supports encoding numbers in a textual format, or when
  /// passed as [int] or [double]. When decoding values, numeric types are
  /// always returned as string.
  static const numeric = GenericType<Object>(TypeOid.numeric);

  /// Must be a [DateTime] (contains year, month and day only)
  static const date = GenericType<DateTime>(TypeOid.date);

  /// Must be encodable via [json.encode].
  ///
  /// Values will be encoded via [json.encode] before being sent to the database.
  static const jsonb = GenericType(TypeOid.jsonb);

  /// Must be encodable via [core.json.encode].
  ///
  /// Values will be encoded via [core.json.encode] before being sent to the database.
  static const json = GenericType(TypeOid.json);

  /// Must be a [List] of [int].
  ///
  /// Each element of the list must fit into a byte (0-255).
  static const byteArray = GenericType<List<int>>(TypeOid.byteArray);

  /// Must be a [String]
  ///
  /// Used for internal pg structure names
  static const name = GenericType<String>(TypeOid.name);

  /// Must be a [String].
  ///
  /// Must contain 32 hexadecimal characters. May contain any number of '-' characters.
  /// When returned from database, format will be xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.
  static const uuid = GenericType<String>(TypeOid.uuid);

  /// Must be a [Point]
  static const point = GenericType<Point>(TypeOid.point);

  /// Must be a [Line]
  static const line = GenericType<Line>(TypeOid.line);

  /// Must be a [LineSegment]
  static const lineSegment = GenericType<LineSegment>(TypeOid.lineSegment);

  /// Must be a [Box]
  static const box = GenericType<Box>(TypeOid.box);

  /// Must be a [Polygon]
  static const polygon = GenericType<Polygon>(TypeOid.polygon);

  /// Must be a [Path]
  static const path = GenericType<Path>(TypeOid.path);

  /// Must be a [Circle]
  static const circle = GenericType<Circle>(TypeOid.circle);

  /// Must be a [List<bool>]
  static const booleanArray = GenericType<List<bool>>(TypeOid.booleanArray);

  /// Must be a [List<int>]
  static const integerArray = GenericType<List<int>>(TypeOid.integerArray);

  /// Must be a [List<int>]
  static const bigIntegerArray =
      GenericType<List<int>>(TypeOid.bigIntegerArray);

  /// Must be a [List<String>]
  static const textArray = GenericType<List<String>>(TypeOid.textArray);

  /// Must be a [List<double>]
  static const doubleArray =
      GenericType<List<core.double>>(TypeOid.doubleArray);

  /// Must be a [String]
  static const varChar = GenericType<String>(TypeOid.varChar);

  /// Must be a [List<String>]
  static const varCharArray = GenericType<List<String>>(TypeOid.varCharArray);

  /// Must be a [List] of encodable objects
  static const jsonbArray = GenericType<List>(TypeOid.jsonbArray);

  /// Must be a [Type].
  static const regtype = GenericType<Type>(TypeOid.regtype);

  /// Impossible to bind to, always null when read.
  static const voidType = GenericType<Object>(TypeOid.voidType);

  /// Must be a [IntRange]
  static const integerRange = GenericType<IntRange>(TypeOid.integerRange);

  /// Must be a [IntRange]
  static const bigIntegerRange = GenericType<IntRange>(TypeOid.bigIntegerRange);

  /// Must be a [DateRange]
  static const dateRange = GenericType<DateRange>(TypeOid.dateRange);

  /// Must be a [Range<Object>]
  ///
  /// Supported element types are the same as for [Type.numeric].
  // static const numrange =
  //     GenericType<ContinuousRange<String>>(TypeOid.numrange);

  /// Must be a [Range<DateTime>]
  static const timestampRange =
      GenericType<DateTimeRange>(TypeOid.timestampRange);

  /// Must be a [Range<DateTime>]
  static const timestampTzRange =
      GenericType<DateTimeRange>(TypeOid.timestampTzRange);

  /// The object ID of this data type.
  final int? oid;

  const Type(this.oid);

  TypedValue<T> value(T value) => TypedValue<T>(this, value);

  @override
  String toString() => 'Type(oid:$oid)';
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
