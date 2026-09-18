import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:postgres/src/v3/resolved_settings.dart';
import 'package:test/test.dart';

void main() {
  group('ResolvedConnectionSettings.isMatchingConnection', () {
    test('connections with different typeRegistry do not match', () {
      final a = ResolvedConnectionSettings(
        ConnectionSettings(typeRegistry: TypeRegistry()),
        null,
      );
      final b = ResolvedConnectionSettings(
        ConnectionSettings(typeRegistry: TypeRegistry()),
        null,
      );

      expect(a.isMatchingConnection(b), isFalse);
      expect(a.isMatchingConnection(a), isTrue);
    });

    test('connections with different securityContext do not match', () {
      final a = ResolvedConnectionSettings(
        ConnectionSettings(securityContext: SecurityContext()),
        null,
      );
      final b = ResolvedConnectionSettings(
        ConnectionSettings(securityContext: SecurityContext()),
        null,
      );

      expect(a.isMatchingConnection(b), isFalse);
      expect(a.isMatchingConnection(a), isTrue);
    });
  });

  group('ResolvedSessionSettings rejects non-positive timeouts', () {
    test('zero connectTimeout throws', () {
      expect(
        () => ResolvedSessionSettings(
          SessionSettings(connectTimeout: Duration.zero),
          null,
        ),
        throwsArgumentError,
      );
    });

    test('negative queryTimeout throws', () {
      expect(
        () => ResolvedSessionSettings(
          SessionSettings(queryTimeout: Duration(seconds: -1)),
          null,
        ),
        throwsArgumentError,
      );
    });

    test('positive timeouts are accepted', () {
      final settings = ResolvedSessionSettings(
        SessionSettings(
          connectTimeout: Duration(seconds: 1),
          queryTimeout: Duration(seconds: 1),
        ),
        null,
      );
      expect(settings.connectTimeout, Duration(seconds: 1));
      expect(settings.queryTimeout, Duration(seconds: 1));
    });
  });
}
