import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:postgres/src/v2/query.dart';
import 'package:test/test.dart';

void main() {
  test('Ensure all types/format type mappings are available and accurate', () {
    const withoutMapping = {
      PgDataType.unspecified, // Can't bind into unspecified type
      PgDataType.unknownType, // Can't bind into unknown type
      PgDataType.voidType, // Can't assign to void
      PgDataType.bigSerial, // Can only be created from a table sequence
      PgDataType.serial,
    };

    for (final type in PgDataType.values) {
      if (withoutMapping.contains(type)) continue;

      expect(
        PostgreSQLFormatIdentifier.typeStringToCodeMap.values.contains(type),
        true,
        reason: 'There should be a type mapping for $type',
      );
      final code = PostgreSQLFormat.dataTypeStringForDataType(type);
      expect(PostgreSQLFormatIdentifier.typeStringToCodeMap[code], type);
    }
  });

  test('Ensure bigserial gets translated to int8', () {
    expect(
        PostgreSQLFormat.dataTypeStringForDataType(PgDataType.serial), 'int4');
  });

  test('Ensure serial gets translated to int4', () {
    expect(PostgreSQLFormat.dataTypeStringForDataType(PgDataType.bigSerial),
        'int8');
  });

  test('Simple replacement', () {
    final result = PostgreSQLFormat.substitute('@id', {'id': 20});
    expect(result, equals('20'));
  });

  test('Trailing/leading space', () {
    final result = PostgreSQLFormat.substitute(' @id ', {'id': 20});
    expect(result, equals(' 20 '));
  });

  test('Two identifiers next to eachother', () {
    final result =
        PostgreSQLFormat.substitute('@id@bob', {'id': 20, 'bob': 13});
    expect(result, equals('2013'));
  });

  test('Identifier with underscores', () {
    final result = PostgreSQLFormat.substitute('@_one_two', {'_one_two': 12});
    expect(result, equals('12'));
  });

  test('Identifier with type info', () {
    final result = PostgreSQLFormat.substitute('@id:int2', {'id': 12});
    expect(result, equals('12'));
  });

  test('Identifiers next to eachother with type info', () {
    final result = PostgreSQLFormat.substitute(
        '@id:int2@foo:float4', {'id': 12, 'foo': 2.0});
    expect(result, equals('122.0'));
  });

  test('Disambiguate PostgreSQL typecast', () {
    final result = PostgreSQLFormat.substitute('@id::jsonb', {'id': '12'});
    expect(result, "'12'::jsonb");
  });

  test('PostgreSQL typecast appears in query', () {
    final results = PostgreSQLFormat.substitute(
        "SELECT * FROM t WHERE id=@id:int2 WHERE blob=@blob::jsonb AND blob='{\"a\":1}'::jsonb",
        {'id': 2, 'blob': '{"key":"value"}'});

    expect(results,
        "SELECT * FROM t WHERE id=2 WHERE blob='{\"key\":\"value\"}'::jsonb AND blob='{\"a\":1}'::jsonb");
  });

  test('Can both provide type and typecast', () {
    final results = PostgreSQLFormat.substitute(
        'SELECT * FROM t WHERE id=@id:int2::int4',
        {'id': 2, 'blob': '{"key":"value"}'});

    expect(results, 'SELECT * FROM t WHERE id=2::int4');
  });

  test('UTF16 symbols with quotes', () {
    final value = "'©™®'";
    final results = PostgreSQLFormat.substitute(
        'INSERT INTO t (t) VALUES (@t)', {'t': value});

    expect(results, "INSERT INTO t (t) VALUES ('''©™®''')");
  });

  test('UTF16 symbols with backslash', () {
    final value = r"'©\™®'";
    final results = PostgreSQLFormat.substitute(
        'INSERT INTO t (t) VALUES (@t)', {'t': value});

    expect(results, r"INSERT INTO t (t) VALUES ( E'''©\\™®''')");
  });

  test('String identifiers get escaped', () {
    final result = PostgreSQLFormat.substitute(
        '@id:text @foo', {'id': "1';select", 'foo': r'3\4'});

    //                         '  1  '  '  ;  s   e   l   e   c  t   '  sp  sp  E  '  3  \  \  4  '
    expect(utf8.encode(result), [
      39,
      49,
      39,
      39,
      59,
      115,
      101,
      108,
      101,
      99,
      116,
      39,
      32,
      32,
      69,
      39,
      51,
      92,
      92,
      52,
      39
    ]);
  });

  test('JSONB operator does not throw', () {
    final query = "SELECT id FROM table WHERE data @> '{\"key\": \"value\"}'";
    final results = PostgreSQLFormat.substitute(query, {});

    expect(results, query);
  });
}
