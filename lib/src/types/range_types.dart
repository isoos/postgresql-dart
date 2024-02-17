import 'package:meta/meta.dart';

/// Describes PostgreSQL range bound state
///
/// https://www.postgresql.org/docs/current/rangetypes.html#RANGETYPES-INCLUSIVITY
enum Bound {
  /// Equivalent to '(' or ')'
  exclusive,

  /// Equivalent to '[' or ']'
  inclusive,
}

/// Describes the bounds of PostgreSQL range types.
///
/// https://www.postgresql.org/docs/current/rangetypes.html#RANGETYPES-INCLUSIVITY
@immutable
class Bounds {
  late final Bound lower;
  late final Bound upper;

  Bounds(this.lower, this.upper);

  ///  Construct a [Bounds] instance from a PostgreSQL [flag] value.
  ///
  ///
  ///  PostgreSQL stores a flag byte that determines range bounds and
  ///  whether a range is empty. The default lower and upper bounds are `exclusive`.
  ///
  ///  A range's flags byte contains these bits:
  ///  - #define RANGE_EMPTY         0x01    (range is empty)
  ///  - #define RANGE_LB_INC        0x02    (lower bound is inclusive)
  ///  - #define RANGE_UB_INC        0x04    (upper bound is inclusive)
  ///  - #define RANGE_LB_INF        0x08    (lower bound is -infinity)
  ///  - #define RANGE_UB_INF        0x10    (upper bound is +infinity)
  ///
  ///  - #define RANGE_LB_NULL       0x20    (lower bound is null (NOT USED))
  ///  - #define RANGE_UB_NULL       0x40    (upper bound is null (NOT USED))
  ///  - #define RANGE_CONTAIN_EMPTY 0x80    (marks a GiST internal-page entry whose subtree contains some empty ranges)
  ///
  /// See https://www.npgsql.org/doc/dev/type-representations.html
  Bounds.fromFlag(int flag) {
    switch (flag) {
      case 0 || 1 || 8 || 16 || 24:
        lower = Bound.exclusive;
        upper = Bound.exclusive;
      case 2 || 18:
        lower = Bound.inclusive;
        upper = Bound.exclusive;
      case 4 || 12:
        lower = Bound.exclusive;
        upper = Bound.inclusive;
      case 6:
        lower = Bound.inclusive;
        upper = Bound.inclusive;
      default:
        throw UnimplementedError('Range flag $flag not implemented');
    }
  }

  int get _lowerFlag {
    switch (lower) {
      case Bound.exclusive:
        return 0;
      case Bound.inclusive:
        return 2;
    }
  }

  int get _upperFlag {
    switch (upper) {
      case Bound.exclusive:
        return 0;
      case Bound.inclusive:
        return 4;
    }
  }

  @override
  String toString() => 'Bounds(${lower.name},${upper.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bounds &&
          runtimeType == other.runtimeType &&
          lower == other.lower &&
          upper == other.upper;

  @override
  int get hashCode => _lowerFlag + _upperFlag;
}

abstract interface class Range<T> {
  late final T? _lower;
  late final T? _upper;
  late final Bounds _bounds;

  Bounds get bounds => _bounds;

  T? get lower => _lower;

  T? get upper => _upper;

  int get flag {
    switch ((lower == null, upper == null)) {
      case (true, true):
        return 24;
      case (true, false):
        return 8 + bounds._upperFlag;
      case (false, true):
        return 16 + bounds._lowerFlag;
      case (false, false):
        return lower == upper ? 1 : bounds._lowerFlag + bounds._upperFlag;
    }
  }

  _throwIfLowerGreaterThanUpper(T? lower, T? upper) {
    if (_lowerGreaterThanUpper(lower, upper)) {
      throw ArgumentError(
          'Range: lower bound must be less than or equal to upper bound');
    }
  }

  bool _lowerGreaterThanUpper(T? lower, T? upper) =>
      lower != null &&
      upper != null &&
      lower is Comparable &&
      lower.compareTo(upper as Comparable) > 0;

  @override
  String toString() => '$runtimeType($lower,$upper,$bounds)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Range<T> && runtimeType == other.runtimeType) {
      return flag == 1
          ? flag == other.flag
          : flag == other.flag && lower == other.lower && upper == other.upper;
    }
    return false;
  }

  @override
  int get hashCode => flag == 1 ? flag : Object.hash(lower, upper, flag);
}

abstract interface class DiscreteRange<T> extends Range<T> {
  DiscreteRange(T? lower, T? upper, Bounds bounds) {
    _throwIfLowerGreaterThanUpper(lower, upper);
    final (l, lBound) = _canonicalizeLower(lower, bounds.lower);
    final (u, uBound) = _canonicalizeUpper(upper, bounds.upper);
    _lower = _lowerGreaterThanUpper(l, u) ? lower : l;
    _upper = u;
    _bounds = Bounds(lBound, uBound);
  }

  (T?, Bound) _canonicalizeLower(T? lower, Bound bound);

  (T?, Bound) _canonicalizeUpper(T? upper, Bound bound);
}

/// Describes PostgreSQL's builtin `int4range` and `int8range`
///
/// https://www.postgresql.org/docs/current/rangetypes.html#RANGETYPES-BUILTIN
class IntRange extends DiscreteRange<int> {
  IntRange(super.lower, super.upper, super.bounds);

  /// Construct an empty [IntRange]
  IntRange.empty() : super(0, 0, Bounds(Bound.inclusive, Bound.exclusive));

  @override
  (int?, Bound) _canonicalizeLower(int? lower, Bound bound) {
    if (lower == null) return (null, Bound.exclusive);
    if (bound == Bound.exclusive) return (lower + 1, Bound.inclusive);
    return (lower, bound);
  }

  @override
  (int?, Bound) _canonicalizeUpper(int? upper, Bound bound) {
    if (upper == null) return (null, Bound.exclusive);
    if (bound == Bound.inclusive) return (upper + 1, Bound.exclusive);
    return (upper, bound);
  }
}

final _z0 = DateTime.utc(1970);

/// Describes PostgreSQL's builtin `daterange`
///
/// https://www.postgresql.org/docs/current/rangetypes.html#RANGETYPES-BUILTIN
class DateRange extends DiscreteRange<DateTime> {
  DateRange(super.lower, super.upper, super.bounds);

  /// Construct an empty [DateRange]
  DateRange.empty() : super(_z0, _z0, Bounds(Bound.inclusive, Bound.exclusive));

  /// Remove hours, minutes, seconds, milliseconds and microseconds from [DateTime]
  DateTime? _removeTime(DateTime? dt) {
    if (dt == null) return null;
    final days = dt.microsecondsSinceEpoch ~/ Duration.microsecondsPerDay;
    final microseconds = days * Duration.microsecondsPerDay;
    return DateTime.fromMicrosecondsSinceEpoch(microseconds, isUtc: true);
  }

  @override
  (DateTime?, Bound) _canonicalizeLower(DateTime? lower, Bound bound) {
    if (lower == null) return (null, Bound.exclusive);
    if (bound == Bound.exclusive) {
      return (_removeTime(lower.add(Duration(days: 1))), Bound.inclusive);
    }
    return (_removeTime(lower), bound);
  }

  @override
  (DateTime?, Bound) _canonicalizeUpper(DateTime? upper, Bound bound) {
    if (upper == null) return (null, Bound.exclusive);
    if (bound == Bound.inclusive) {
      return (_removeTime(upper.add(Duration(days: 1))), Bound.exclusive);
    }
    return (_removeTime(upper), bound);
  }
}

/// Describes PostgreSQL's continuous builtin range types:
/// - `numrange`
/// - `tsrange`
/// - `tstzrange`
///
/// https://www.postgresql.org/docs/current/rangetypes.html#RANGETYPES-BUILTIN
interface class ContinuousRange<T> extends Range<T> {
  ContinuousRange(T? lower, T? upper, Bounds bounds) {
    _throwIfLowerGreaterThanUpper(lower, upper);
    _lower = lower;
    _upper = upper;
    _bounds = _canonicalizeNullBounds(bounds);
  }

  /// Infinity (or `null`-valued) bounds are always stored as [Bound.exclusive]
  ///
  /// https://www.postgresql.org/docs/current/rangetypes.html#RANGETYPES-INFINITE
  Bounds _canonicalizeNullBounds(Bounds bounds) {
    switch ((lower == null, upper == null)) {
      case (true, true):
        return Bounds(Bound.exclusive, Bound.exclusive);
      case (false, true):
        return Bounds(bounds.lower, Bound.exclusive);
      case (true, false):
        return Bounds(Bound.exclusive, bounds.upper);
      case (false, false):
        return bounds;
    }
  }
}

class DateTimeRange extends ContinuousRange<DateTime> {
  DateTimeRange(super.lower, super.upper, super.bounds);

  /// Construct an empty [TsRange]
  DateTimeRange.empty()
      : super(_z0, _z0, Bounds(Bound.inclusive, Bound.exclusive));
}
