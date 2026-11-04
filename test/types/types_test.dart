import 'package:postgres/postgres.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('LSN type', () {
    test('- Can parse LSN String', () {
      // These two numbers are equal but in different formats
      // see: https://www.postgresql.org/docs/current/datatype-pg-lsn.html
      final lsn = LSN.fromString('16/B374D848');
      expect(lsn.value, 97500059720);
    });

    test('- Can convert LSN to String', () {
      final lsn = LSN(97500059720);
      expect(lsn.toString(), '16/B374D848');
    });
  });

  group('PgPoint type', () {
    test('- PgPoint hashcode', () {
      final point = Point(1.0, 2.0);
      final point2 = Point(2.0, 1.0);
      expect(point.hashCode, isNot(point2.hashCode));
    });
  });
}
