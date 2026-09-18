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

    test('connections with different (but otherwise equal) onOpen closures '
        'still match', () {
      // A fresh closure per call is a natural Dart pattern - `onOpen` only
      // runs once, at connection creation, so it must not prevent reuse of
      // an already-open connection. `typeRegistry` is shared explicitly
      // since two default `TypeRegistry()` instances aren't `==` to each
      // other, which would otherwise mask what this test is checking.
      final typeRegistry = TypeRegistry();
      final a = ResolvedConnectionSettings(
        ConnectionSettings(onOpen: (c) async {}, typeRegistry: typeRegistry),
        null,
      );
      final b = ResolvedConnectionSettings(
        ConnectionSettings(onOpen: (c) async {}, typeRegistry: typeRegistry),
        null,
      );

      expect(a.isMatchingConnection(b), isTrue);
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
