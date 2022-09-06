import 'package:postgres/src/time_converters.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('test time conversion from pg to dart and vice versa', () {
    test('pgTimeToDateTime produces correct DateTime', () {
      final timeFromPg = dateTimeFromMicrosecondsSinceY2k(0);

      expect(timeFromPg.year, 2000);
      expect(timeFromPg.month, 1);
      expect(timeFromPg.day, 1);
    });

    test('dateTimeToPgTime produces correct microseconds since 2000-01-01', () {
      // final timeFromPg = pgTimeToDateTime(0);
      final dateTime = DateTime.utc(2000, 1, 1);
      final pgTime = dateTimeToMicrosecondsSinceY2k(dateTime);
      expect(pgTime, 0);
    });
  });
}
