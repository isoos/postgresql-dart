import 'dart:core';

import 'package:meta/meta.dart';

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

  @override
  String toString() => 'Point($latitude,$longitude)';
}

/// Describes PostgreSQL's geometric type: `line`.
///
/// A line as defined by the linear equation _ax + by + c = 0_.
///
/// See https://www.postgresql.org/docs/current/datatype-geometric.html#DATATYPE-LINE
///
@immutable
class Line {
  final double a, b, c;

  Line(this.a, this.b, this.c) {
    if (a == 0 && b == 0) {
      throw ArgumentError('Line: a and b cannot both be zero');
    }
  }

  @override
  String toString() => 'Line($a,$b,$c)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Line &&
          runtimeType == other.runtimeType &&
          a == other.a &&
          b == other.b &&
          c == other.c;

  @override
  int get hashCode => Object.hash(a, b, c);
}

/// Describes PostgreSQL's geometric type: `lseg`.
@immutable
class LineSegment {
  final Point p1, p2;

  LineSegment(this.p1, this.p2);

  @override
  String toString() => 'LineSegment($p1,$p2)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineSegment &&
          runtimeType == other.runtimeType &&
          p1 == other.p1 &&
          p2 == other.p2;

  @override
  int get hashCode => Object.hash(p1, p2);
}

/// Describes PostgreSQL's geometric type: `box`.
@immutable
class Box {
  late final Point _p1, _p2;

  /// Construct a [Box].
  ///
  /// Reorders point coordinates as needed to store the upper right and lower left corners, in that order.
  ///
  /// https://www.postgresql.org/docs/current/datatype-geometric.html#DATATYPE-GEOMETRIC-BOXES
  Box(Point p1, Point p2) {
    final (x1, x2) = p1.latitude >= p2.latitude
        ? (p1.latitude, p2.latitude)
        : (p2.latitude, p1.latitude);
    final (y1, y2) = p1.longitude >= p2.longitude
        ? (p1.longitude, p2.longitude)
        : (p2.longitude, p1.longitude);
    _p1 = Point(x1, y1);
    _p2 = Point(x2, y2);
  }

  Point get p1 => _p1;

  Point get p2 => _p2;

  @override
  String toString() => 'Box($p1,$p2)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Box &&
          runtimeType == other.runtimeType &&
          p1 == other.p1 &&
          p2 == other.p2;

  @override
  int get hashCode => Object.hash(p1, p2);
}

/// Describes PostgreSQL's geometric type: `polygon`.
@immutable
class Polygon {
  final List<Point> _points;

  List<Point> get points => _points;

  Polygon(Iterable<Point> points) : _points = List.unmodifiable(points) {
    if (_points.isEmpty) {
      throw ArgumentError('$runtimeType: at least one point required');
    }
  }

  @override
  String toString() => 'Polygon(${points.map((e) => e.toString()).join(',')})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Polygon &&
          runtimeType == other.runtimeType &&
          _allPointsAreEqual(other.points);

  bool _allPointsAreEqual(List<Point> otherPoints) {
    if (points.length != otherPoints.length) return false;
    for (int i = 0; i < points.length; i++) {
      if (points[i] != otherPoints[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(points);
}

/// Describes PostgreSQL's geometric type: `path`.
class Path extends Polygon {
  final bool open;

  Path(super.points, {required this.open});

  @override
  String toString() =>
      'Path(${open ? 'open' : 'closed'},${points.map((e) => e.toString()).join(',')})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Path &&
          runtimeType == other.runtimeType &&
          open == other.open &&
          _allPointsAreEqual(other.points);

  @override
  int get hashCode => Object.hashAll([...points, open]);
}

class Circle {
  final Point center;
  final double radius;

  Circle(this.center, this.radius) {
    if (radius < 0) throw ArgumentError('Circle: radius must not negative');
  }

  @override
  String toString() => 'Circle($center,$radius)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Circle &&
          runtimeType == other.runtimeType &&
          radius == other.radius &&
          center == other.center;

  @override
  int get hashCode => Object.hash(center, radius);
}
