import 'dart:async';

import 'package:pool/pool.dart';
import 'package:postgres/src/utils/package_pool_ext.dart';
import 'package:test/test.dart';

void main() {
  group('package:pool extensions', () {
    test('acquire with timeout succeeds - no parallel use', () async {
      final pool = Pool(1);
      final x = await pool.withRequestTimeout(
        timeout: Duration(seconds: 1),
        (_) async {
          return 1;
        },
      );
      expect(x, 1);
      final r = await pool.request();
      r.release();
      await pool.close();
    });

    test('acquire with timeout succeeds - quick parallel use', () async {
      final pool = Pool(1);
      final other = await pool.request();
      Timer(Duration(seconds: 1), other.release);
      var remainingMillis = 0;
      final x = await pool.withRequestTimeout(
        timeout: Duration(seconds: 2),
        (remaining) async {
          remainingMillis = remaining.inMilliseconds;
          return 1;
        },
      );
      expect(x, 1);
      final r = await pool.request();
      r.release();
      await pool.close();
      expect(remainingMillis, greaterThan(500));
      expect(remainingMillis, lessThan(1500));
    });

    test('acquire with timeout fails - long parallel use', () async {
      final pool = Pool(1);
      final other = await pool.request();
      Timer(Duration(seconds: 2), other.release);
      await expectLater(
        pool.withRequestTimeout(
          timeout: Duration(seconds: 1),
          (_) async {
            return 1;
          },
        ),
        throwsA(isA<TimeoutException>()),
      );
      final sw = Stopwatch()..start();
      final r = await pool.request();
      sw.stop();
      r.release();
      await pool.close();
      expect(sw.elapsedMilliseconds, greaterThan(500));
      expect(sw.elapsedMilliseconds, lessThan(1500));
    });
  });
}
