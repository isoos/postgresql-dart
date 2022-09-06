import 'package:postgres/postgres.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

// These two numbers are equal but in different formats
// 
// see: https://www.postgresql.org/docs/current/datatype-pg-lsn.html
const _lsnStringSample = '16/B374D848';
const _lsnIntegerSample = 97500059720;

void main() {
  group('LSN type', () {
    test('- Can parse LSN String', () {
      final lsn = LSN.fromString(_lsnStringSample);

      expect(lsn.value, _lsnIntegerSample);
    });

    test('- Can convert LSN to String', () {
      final lsn = LSN(_lsnIntegerSample);

      expect(lsn.toString(), _lsnStringSample);
    });
  });
}
