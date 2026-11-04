import 'package:postgres/messages.dart';
import 'package:postgres/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('buildExceptionFromErrorFields', () {
    test('parses well-formed position/line fields', () {
      final ex = buildExceptionFromErrorFields([
        ErrorField(ErrorFieldId.message, 'oops'),
        ErrorField(ErrorFieldId.position, '12'),
        ErrorField(ErrorFieldId.line, '3'),
      ]);

      expect(ex.position, 12);
      expect(ex.lineNumber, 3);
    });

    test('does not throw on a malformed position field', () {
      final ex = buildExceptionFromErrorFields([
        ErrorField(ErrorFieldId.message, 'oops'),
        ErrorField(ErrorFieldId.position, 'not-a-number'),
      ]);

      expect(ex.position, isNull);
      expect(ex.message, 'oops');
    });
  });
}
