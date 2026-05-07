import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('TypedValue parameter type propagation', (server) {
    late Connection conn;

    setUp(() async {
      conn = await server.newConnection();
    });

    tearDown(() async {
      await conn.close();
    });

    test('daterange @> TypedValue(Type.date) without inline annotation',
        () async {
      final result = await conn.execute(
        Sql.named(
          "SELECT daterange('2026-01-01','2026-01-10','[)') @> @d",
        ),
        parameters: {'d': TypedValue(Type.date, DateTime.utc(2026, 1, 5))},
      );
      expect(result.single.single, isTrue);
    });

    test('TypedValue date outside range returns false', () async {
      final result = await conn.execute(
        Sql.named(
          "SELECT daterange('2026-01-01','2026-01-10','[)') @> @d",
        ),
        parameters: {'d': TypedValue(Type.date, DateTime.utc(2026, 1, 20))},
      );
      expect(result.single.single, isFalse);
    });

    test('integerArray && TypedValue(_int4) without inline annotation',
        () async {
      final result = await conn.execute(
        Sql.named("SELECT ARRAY[1,2,3] && @arr"),
        parameters: {
          'arr': TypedValue(Type.integerArray, [2, 5]),
        },
      );
      expect(result.single.single, isTrue);
    });

    test('inline annotation takes precedence over TypedValue type', () async {
      // :date annotation wins even though we pass TypedValue(Type.date, ...)
      final result = await conn.execute(
        Sql.named(
          "SELECT daterange('2026-01-01','2026-01-10','[)') @> @d:date",
        ),
        parameters: {'d': TypedValue(Type.date, DateTime.utc(2026, 1, 5))},
      );
      expect(result.single.single, isTrue);
    });

    test('positional TypedValue without explicit types list', () async {
      final result = await conn.execute(
        Sql(r"SELECT daterange('2026-01-01','2026-01-10','[)') @> $1"),
        parameters: [TypedValue(Type.date, DateTime.utc(2026, 1, 5))],
      );
      expect(result.single.single, isTrue);
    });

    test('unspecified TypedValue still infers type from value', () async {
      // Type.unspecified means the driver should fall back to text encoding,
      // which PostgreSQL can handle for simple equality checks.
      final result = await conn.execute(
        Sql.named('SELECT @v::int = 42'),
        parameters: {'v': TypedValue(Type.unspecified, 42)},
      );
      expect(result.single.single, isTrue);
    });

    // PostgreSQL cannot resolve anyelement polymorphic parameters when the
    // driver sends OID 0 ("unknown") in the Parse message. TypedValue must
    // propagate its type to Parse so the function can be resolved.
    test('anyelement polymorphic function resolves with TypedValue type',
        () async {
      await conn.execute(r'''
        CREATE OR REPLACE FUNCTION pg_temp.identity(anyelement)
        RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 $$
      ''');

      final intResult = await conn.execute(
        Sql.named('SELECT pg_temp.identity(@v)'),
        parameters: {'v': TypedValue(Type.integer, 42)},
      );
      expect(intResult.single.single, 42);

      final boolResult = await conn.execute(
        Sql.named('SELECT pg_temp.identity(@v)'),
        parameters: {'v': TypedValue(Type.boolean, true)},
      );
      expect(boolResult.single.single, isTrue);
    });
  });
}
