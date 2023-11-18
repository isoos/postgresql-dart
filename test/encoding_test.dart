import 'dart:async';
import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:postgres/src/types/text_codec.dart';
import 'package:postgres/src/types/type_registry.dart';
import 'package:test/test.dart';

import 'docker.dart';

late Connection conn;

void main() {
  withPostgresServer('Binary encoders', (server) {
    setUp(() async {
      conn = await server.newConnection();
    });

    tearDown(() async {
      await conn.close();
    });

    test('bool', () async {
      await expectReversible(
        'boolean',
        [true, false],
        expectedDartType: 'bool',
      );
    });

    test('smallint', () async {
      await expectReversible(
        'int2',
        [-1, 0, 1],
        expectedDartType: 'int',
      );
    });

    test('integer', () async {
      await expectReversible(
        'int4',
        [-1, 0, 1],
        expectedDartType: 'int',
      );
    });

    test('serial', () async {
      await expectReversible(
        'serial4',
        [0, 1],
        expectedDartType: 'int',
      );
    });

    test('bigint', () async {
      await expectReversible(
        'int8',
        [-1, 0, 1],
        expectedDartType: 'int',
      );
    });

    test('bigserial', () async {
      await expectReversible(
        'serial8',
        [0, 1],
        expectedDartType: 'int',
      );
    });

    test('text', () async {
      await expectReversible(
        'text',
        ['', 'foo', 'foo\n', 'foo\nbar;s'],
        negative: 0,
        expectedDartType: 'String',
      );
    });

    test('real', () async {
      await expectReversible(
        'float4',
        [-1.0, 0.0, 1.0],
        expectedDartType: 'double',
      );
    });

    test('double', () async {
      await expectReversible(
        'float8',
        [-1.0, 0.0, 1.0],
        expectedDartType: 'double',
      );
    });

    test('date', () async {
      await expectReversible(
        'date',
        [
          DateTime.utc(1920, 10, 1),
          DateTime.utc(2120, 10, 5),
          DateTime.utc(2016, 10, 1),
        ],
        expectedDartType: 'DateTime',
      );
    });

    test('timestamp', () async {
      await expectReversible(
        'timestamp',
        [
          DateTime.utc(1920, 10, 1),
          DateTime.utc(2120, 10, 5),
          DateTime.utc(2016, 10, 1),
        ],
        expectedDartType: 'DateTime',
      );
    });

    test('timestamptz', () async {
      await expectReversible(
        'timestamptz',
        [
          DateTime.utc(1920, 10, 1),
          DateTime.utc(2120, 10, 5),
          DateTime.utc(2016, 10, 1),
        ],
        expectedDartType: 'DateTime',
      );
    });

    test('interval', () async {
      await expectReversible(
        'interval',
        [
          Interval(microseconds: 12345678),
          Interval(days: 1, microseconds: 15),
          Interval(days: -1, months: 5),
        ],
        expectedDartType: 'Interval',
      );
    });

    test('numeric', () async {
      await expectReversible(
        'numeric',
        [
          '-123400000.20000',
          '-123400001.00002',
          '1000000000000000000000000000.0000000000000000000000000001',
          '3141592653589793238462643383279502.1618033988749894848204586834365638',
          '-3141592653589793238462643383279502.1618033988749894848204586834365638',
          '0',
          '0.0',
          '0.1',
          '0.0001',
          '0.00001',
          '0.000001',
          '0.000000001',
          '1.000000000',
          '1000.000000000',
          '10000.000000000',
          '100000000.00000000',
          'NaN',
        ],
        expectedDartType: 'String',
      );
    });

    test('jsonb', () async {
      await expectReversible(
        'jsonb',
        [
          'string',
          2,
          ['foo'],
          {
            'key': 'val',
            'key1': 1,
            'array': ['foo'],
          },
        ],
        skipNegative: true,
      );

      try {
        await conn.execute(Sql.named('INSERT INTO t (v) VALUES (@v:jsonb)'),
            parameters: {'v': DateTime.now()});
        fail('unreachable');
      } on JsonUnsupportedObjectError catch (_) {}
    });

    test('bytea', () async {
      await expectReversible(
        'bytea',
        [
          [0],
          [1, 2, 3, 4, 5],
          [255, 254, 253],
        ],
        expectedDartType: 'List<int>',
      );
    });

    test('uuid', () async {
      await expectReversible(
        'uuid',
        [
          '00000000-0000-0000-0000-000000000000',
          '12345678-abcd-efab-cdef-012345678901',
        ],
        negative: 0,
        expectedDartType: 'String',
      );
    });

    test('Invalid UUID encoding', () async {
      final invalids = [
        'z0000000-0000-0000-0000-000000000000',
        '0000000-0000-0000-0000-000000000000',
        '00000000-0000-0000-0000-000000000000f',
      ];

      await conn.execute('CREATE TEMPORARY TABLE IF NOT EXISTS t (v uuid)');

      for (final value in invalids) {
        try {
          await conn.execute(
              Sql.named('INSERT INTO t (v) VALUES (@v:uuid) RETURNING v'),
              parameters: {'v': value});
          fail('unreachable');
        } on FormatException catch (e) {
          expect(e.toString(), contains('Invalid UUID string'));
        }
      }
    });

    test('varchar', () async {
      await expectReversible(
        'varchar',
        ['', 'foo', 'foo\n', 'foo\nbar;s'],
        negative: 0,
        expectedDartType: 'String',
      );
    });

    test('json', () async {
      await expectReversible(
        'jsonb',
        [
          'string',
          2,
          ['foo'],
          {
            'key': 'val',
            'key1': 1,
            'array': ['foo'],
          },
        ],
        skipNegative: true,
      );

      try {
        await conn.execute(Sql.named('INSERT INTO t (v) VALUES (@v:jsonb)'),
            parameters: {'v': DateTime.now()});
        fail('unreachable');
      } on JsonUnsupportedObjectError catch (_) {}

      try {
        await conn.execute(Sql.named('INSERT INTO t (v) VALUES (@v:json)'),
            parameters: {'v': DateTime.now()});
        fail('unreachable');
      } on JsonUnsupportedObjectError catch (_) {}
    });

    test('point', () async {
      await expectReversible(
        'point',
        [
          Point(0, 0),
          Point(100, 123.456),
          Point(0.001, -999),
        ],
        expectedDartType: 'Point',
      );
    });

    test('booleanArray', () async {
      await expectReversible(
        '_bool',
        [
          <bool>[],
          [false, true],
          [true],
        ],
        expectedDartType: 'List<bool>',
      );
    });

    test('integerArray', () async {
      await expectReversible(
        '_int4',
        [
          <int>[],
          [-1, 0, 200],
          [-123],
        ],
        expectedDartType: 'List<int>',
      );
    });

    test('bigIntegerArray', () async {
      await expectReversible(
        '_int8',
        [
          <int>[],
          [-1, 0, 200],
          [-123],
        ],
        expectedDartType: 'List<int>',
      );
    });

    test('doubleArray', () async {
      await expectReversible(
        '_float8',
        [
          <double>[],
          [-123.0, 0.0, 1.0],
          [0.001, 45.678],
        ],
        expectedDartType: 'List<double>',
      );
    });

    test('varCharArray', () async {
      await expectReversible(
        '_varchar',
        [
          <String>[],
          ['', 'foo', 'foo\n', 'foo\nbar;s'],
        ],
        negative: 0,
        expectedDartType: 'List<String>',
      );
    });

    test('textArray', () async {
      await expectReversible(
        '_text',
        [
          <String>[],
          ['', 'foo', 'foo\n', 'foo\nbar;s'],
        ],
        negative: 0,
        expectedDartType: 'List<String>',
      );
    });

    test('jsonbArray', () async {
      await expectReversible(
        '_jsonb',
        [
          [],
          ['', 'foo', 'foo\n', 'foo\nbar;s', 2, 0.1, true],
          [
            {'a': false},
            {},
            2,
            ['a'],
            {
              'a': ['b']
            }
          ],
        ],
        skipNegative: true,
      );

      try {
        await conn.execute(Sql.named('INSERT INTO t (v) VALUES (@v:_jsonb)'),
            parameters: {
              'v': [DateTime.now()]
            });
        fail('unreachable');
      } on JsonUnsupportedObjectError catch (_) {}
    });

    test('void', () async {
      final result = await conn.execute(Sql.named('SELECT NULL::void AS r'));
      expect(result.schema.columns.single.typeOid, TypeOid.voidType);

      expect(result, [
        [null]
      ]);

      expect(
        () =>
            TypeRegistry().encodeValue(1, type: Type.voidType, encoding: utf8),
        throwsArgumentError,
      );
    });

    test('regtype', () async {
      await expectReversible(
        'regtype',
        [Type.bigInteger, Type.voidType],
        skipNegative: true,
      );
    });
  });

  group('Text encoders', () {
    final encoder = PostgresTextEncoder();

    test('Escape strings', () {
      //                                                       '   b   o    b   '
      expect(
          utf8.encode(encoder.convert('bob')), equals([39, 98, 111, 98, 39]));

      //                                                         '   b   o   \n   b   '
      expect(utf8.encode(encoder.convert('bo\nb')),
          equals([39, 98, 111, 10, 98, 39]));

      //                                                         '   b   o   \r   b   '
      expect(utf8.encode(encoder.convert('bo\rb')),
          equals([39, 98, 111, 13, 98, 39]));

      //                                                         '   b   o  \b   b   '
      expect(utf8.encode(encoder.convert('bo\bb')),
          equals([39, 98, 111, 8, 98, 39]));

      //                                                     '   '   '   '
      expect(utf8.encode(encoder.convert("'")), equals([39, 39, 39, 39]));

      //                                                      '   '   '   '   '   '
      expect(
          utf8.encode(encoder.convert("''")), equals([39, 39, 39, 39, 39, 39]));

      //                                                       '   '   '   '   '   '
      expect(
          utf8.encode(encoder.convert("''")), equals([39, 39, 39, 39, 39, 39]));

      //                                                       sp   E   '   \   \   '   '   '   '   '
      expect(utf8.encode(encoder.convert(r"\''")),
          equals([32, 69, 39, 92, 92, 39, 39, 39, 39, 39]));

      //                                                      sp   E   '   \   \   '   '   '
      expect(utf8.encode(encoder.convert(r"\'")),
          equals([32, 69, 39, 92, 92, 39, 39, 39]));
    });

    test('Encode DateTime', () {
      // Get users current timezone
      final tz = DateTime(2001, 2, 3).timeZoneOffset;
      final tzOffsetDelimiter = '${tz.isNegative ? '-' : '+'}'
          '${tz.abs().inHours.toString().padLeft(2, '0')}'
          ':${(tz.inSeconds % 60).toString().padLeft(2, '0')}';

      final pairs = {
        '2001-02-03T00:00:00.000$tzOffsetDelimiter':
            DateTime(2001, DateTime.february, 3),
        '2001-02-03T04:05:06.000$tzOffsetDelimiter':
            DateTime(2001, DateTime.february, 3, 4, 5, 6, 0),
        '2001-02-03T04:05:06.999$tzOffsetDelimiter':
            DateTime(2001, DateTime.february, 3, 4, 5, 6, 999),
        '0010-02-03T04:05:06.123$tzOffsetDelimiter BC':
            DateTime(-10, DateTime.february, 3, 4, 5, 6, 123),
        '0010-02-03T04:05:06.000$tzOffsetDelimiter BC':
            DateTime(-10, DateTime.february, 3, 4, 5, 6, 0),
        '012345-02-03T04:05:06.000$tzOffsetDelimiter BC':
            DateTime(-12345, DateTime.february, 3, 4, 5, 6, 0),
        '012345-02-03T04:05:06.000$tzOffsetDelimiter':
            DateTime(12345, DateTime.february, 3, 4, 5, 6, 0)
      };

      pairs.forEach((k, v) {
        expect(encoder.convert(v, escapeStrings: false), "'$k'");
      });
    });

    test('Encode Double', () {
      final pairs = {
        "'nan'": double.nan,
        "'infinity'": double.infinity,
        "'-infinity'": double.negativeInfinity,
        '1.7976931348623157e+308': double.maxFinite,
        '5e-324': double.minPositive,
        '-0.0': -0.0,
        '0.0': 0.0
      };

      pairs.forEach((k, v) {
        expect(encoder.convert(v, escapeStrings: false), k);
      });
    });

    test('Encode Int', () {
      expect(encoder.convert(1), '1');
      expect(encoder.convert(1234324323), '1234324323');
      expect(encoder.convert(-1234324323), '-1234324323');
    });

    test('Encode Bool', () {
      expect(encoder.convert(true), 'TRUE');
      expect(encoder.convert(false), 'FALSE');
    });

    test('Encode JSONB', () {
      expect(encoder.convert({'a': 'b'}, escapeStrings: false), '{"a":"b"}');
      expect(encoder.convert({'a': true}, escapeStrings: false), '{"a":true}');
      expect(
          encoder.convert({'b': false}, escapeStrings: false), '{"b":false}');
      expect(encoder.convert({'a': true}), '\'{"a":true}\'');
      expect(encoder.convert({'b': false}), '\'{"b":false}\'');
    });

    test('Attempt to infer unknown type throws exception', () {
      try {
        encoder.convert(Object());
        fail('unreachable');
      } on PgException catch (e) {
        expect(e.toString(), contains('Could not infer type'));
      }
    });
  });
}

Future expectReversible(
  String typeName,
  List values, {
  String? expectedDartType,
  bool skipNegative = false,
  Object negative = 'non-value',
}) async {
  await conn.execute('CREATE TEMPORARY TABLE IF NOT EXISTS t (v $typeName)');

  for (final value in values) {
    final result = await conn.execute(
        Sql.named('INSERT INTO t (v) VALUES (@v:$typeName) RETURNING v'),
        parameters: {'v': value});
    expect(result.first.first, equals(value));
  }

  if (!skipNegative) {
    try {
      await conn.execute(Sql.named('INSERT INTO t (v) VALUES (@v:$typeName)'),
          parameters: {'v': negative});
      fail('unreachable');
    } on FormatException catch (e) {
      expect(
          e.toString(),
          contains(expectedDartType == null
              ? 'Expected: '
              : 'Expected: $expectedDartType'));
    }
  }
}
