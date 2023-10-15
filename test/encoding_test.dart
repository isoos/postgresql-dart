import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:postgres/postgres.dart';
import 'package:postgres/src/binary_codec.dart';
import 'package:postgres/src/text_codec.dart';
import 'package:postgres/src/v3/types.dart';
import 'package:test/test.dart';

import 'docker.dart';

late PostgreSQLConnection conn;

void main() {
  withPostgresServer('Binary encoders', (server) {
    setUp(() async {
      conn = await server.newPostgreSQLConnection();
      await conn.open();
    });

    tearDown(() async {
      await conn.close();
    });

    // expectInverse ensures that:
    // 1. encoder/decoder is reversible
    // 2. can actually encode and decode a real pg query
    // it also creates a table named t with column v of type being tested
    test('bool', () async {
      await expectInverse(true, PgDataType.boolean);
      await expectInverse(false, PgDataType.boolean);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:boolean)',
            substitutionValues: {'v': 'not-bool'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: bool'));
      }
    });

    test('smallint', () async {
      await expectInverse(-1, PgDataType.smallInteger);
      await expectInverse(0, PgDataType.smallInteger);
      await expectInverse(1, PgDataType.smallInteger);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:int2)',
            substitutionValues: {'v': 'not-int2'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: int'));
      }
    });

    test('integer', () async {
      await expectInverse(-1, PgDataType.integer);
      await expectInverse(0, PgDataType.integer);
      await expectInverse(1, PgDataType.integer);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:int4)',
            substitutionValues: {'v': 'not-int4'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: int'));
      }
    });

    test('serial', () async {
      await expectInverse(0, PgDataType.serial);
      await expectInverse(1, PgDataType.serial);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:int4)',
            substitutionValues: {'v': 'not-serial'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: int'));
      }
    });

    test('bigint', () async {
      await expectInverse(-1, PgDataType.bigInteger);
      await expectInverse(0, PgDataType.bigInteger);
      await expectInverse(1, PgDataType.bigInteger);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:int8)',
            substitutionValues: {'v': 'not-int8'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: int'));
      }
    });

    test('bigserial', () async {
      await expectInverse(0, PgDataType.bigSerial);
      await expectInverse(1, PgDataType.bigSerial);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:int8)',
            substitutionValues: {'v': 'not-bigserial'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: int'));
      }
    });

    test('text', () async {
      await expectInverse('', PgDataType.text);
      await expectInverse('foo', PgDataType.text);
      await expectInverse('foo\n', PgDataType.text);
      await expectInverse('foo\nbar;s', PgDataType.text);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:text)',
            substitutionValues: {'v': 0});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: String'));
      }
    });

    test('real', () async {
      await expectInverse(-1.0, PgDataType.real);
      await expectInverse(0.0, PgDataType.real);
      await expectInverse(1.0, PgDataType.real);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:float4)',
            substitutionValues: {'v': 'not-real'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: double'));
      }
    });

    test('double', () async {
      await expectInverse(-1.0, PgDataType.double);
      await expectInverse(0.0, PgDataType.double);
      await expectInverse(1.0, PgDataType.double);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:float8)',
            substitutionValues: {'v': 'not-double'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: double'));
      }
    });

    test('date', () async {
      await expectInverse(DateTime.utc(1920, 10, 1), PgDataType.date);
      await expectInverse(DateTime.utc(2120, 10, 5), PgDataType.date);
      await expectInverse(DateTime.utc(2016, 10, 1), PgDataType.date);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:date)',
            substitutionValues: {'v': 'not-date'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: DateTime'));
      }
    });

    test('timestamp', () async {
      await expectInverse(
          DateTime.utc(1920, 10, 1), PgDataType.timestampWithoutTimezone);
      await expectInverse(
          DateTime.utc(2120, 10, 5), PgDataType.timestampWithoutTimezone);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:timestamp)',
            substitutionValues: {'v': 'not-timestamp'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: DateTime'));
      }
    });

    test('timestamptz', () async {
      await expectInverse(
          DateTime.utc(1920, 10, 1), PgDataType.timestampWithTimezone);
      await expectInverse(
          DateTime.utc(2120, 10, 5), PgDataType.timestampWithTimezone);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:timestamptz)',
            substitutionValues: {'v': 'not-timestamptz'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: DateTime'));
      }
    });

    test('interval', () async {
      await expectInverse(Duration(minutes: 15), PgDataType.interval);
      await expectInverse(Duration(days: 1, minutes: 15), PgDataType.interval);
      await expectInverse(-Duration(days: 1, seconds: 5), PgDataType.interval);
      await expectInverse(
          Duration(days: 365 * 100000, microseconds: 1), PgDataType.interval);
      await expectInverse(
          -Duration(days: 365 * 100000, microseconds: 1), PgDataType.interval);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:interval)',
            substitutionValues: {'v': 'not-interval'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: Duration'));
      }
    });

    test('numeric', () async {
      final binaries = {
        '-123400000.20000': [
          0,
          4,
          0,
          2,
          64,
          0,
          0,
          5,
          0,
          1,
          9,
          36,
          0,
          0,
          7,
          208
        ],
        '-123400001.00002': [
          0,
          5,
          0,
          2,
          64,
          0,
          0,
          5,
          0,
          1,
          9,
          36,
          0,
          1,
          0,
          0,
          7,
          208
        ],
        '0.00001': [0, 1, 255, 254, 0, 0, 0, 5, 3, 232],
        '10000.000000000': [0, 1, 0, 1, 0, 0, 0, 9, 0, 1],
        'NaN': [0, 0, 0, 0, 192, 0, 0, 0],
        '0': [0, 0, 0, 0, 0, 0, 0, 0], // 0 or 0.
        '0.0': [0, 0, 0, 0, 0, 0, 0, 1], // .0 or 0.0
      };

      final encoder = PostgresBinaryEncoder<Object>(PgDataType.numeric);
      binaries.forEach((key, value) {
        final uint8List = Uint8List.fromList(value);
        final res = encoder.convert(key, utf8);
        expect(res, uint8List);
      });

      await expectInverse(
          '1000000000000000000000000000.0000000000000000000000000001',
          PgDataType.numeric);
      await expectInverse(
          '3141592653589793238462643383279502.1618033988749894848204586834365638',
          PgDataType.numeric);
      await expectInverse(
          '-3141592653589793238462643383279502.1618033988749894848204586834365638',
          PgDataType.numeric);
      await expectInverse('0.0', PgDataType.numeric);
      await expectInverse('0.1', PgDataType.numeric);
      await expectInverse('0.0001', PgDataType.numeric);
      await expectInverse('0.00001', PgDataType.numeric);
      await expectInverse('0.000001', PgDataType.numeric);
      await expectInverse('0.000000001', PgDataType.numeric);
      await expectInverse('1.000000000', PgDataType.numeric);
      await expectInverse('1000.000000000', PgDataType.numeric);
      await expectInverse('10000.000000000', PgDataType.numeric);
      await expectInverse('100000000.00000000', PgDataType.numeric);
      await expectInverse('NaN', PgDataType.numeric);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:numeric)',
            substitutionValues: {'v': 'not-numeric'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: String'));
      }
    });

    test('jsonb', () async {
      await expectInverse('string', PgDataType.jsonb);
      await expectInverse(2, PgDataType.jsonb);
      await expectInverse(['foo'], PgDataType.jsonb);
      await expectInverse({
        'key': 'val',
        'key1': 1,
        'array': ['foo']
      }, PgDataType.jsonb);

      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:jsonb)',
            substitutionValues: {'v': DateTime.now()});
        fail('unreachable');
      } on JsonUnsupportedObjectError catch (_) {}
    });

    test('bytea', () async {
      await expectInverse([0], PgDataType.byteArray);
      await expectInverse([1, 2, 3, 4, 5], PgDataType.byteArray);
      await expectInverse([255, 254, 253], PgDataType.byteArray);

      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:bytea)',
            substitutionValues: {'v': DateTime.now()});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: List<int>'));
      }
    });

    test('uuid', () async {
      await expectInverse(
          '00000000-0000-0000-0000-000000000000', PgDataType.uuid);
      await expectInverse(
          '12345678-abcd-efab-cdef-012345678901', PgDataType.uuid);

      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:uuid)',
            substitutionValues: {'v': DateTime.now()});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: String'));
      }
    });

    test('varchar', () async {
      await expectInverse('', PgDataType.varChar);
      await expectInverse('foo', PgDataType.varChar);
      await expectInverse('foo\n', PgDataType.varChar);
      await expectInverse('foo\nbar;s', PgDataType.varChar);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:varchar)',
            substitutionValues: {'v': 0});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: String'));
      }
    });

    test('json', () async {
      await expectInverse('string', PgDataType.json);
      await expectInverse(2, PgDataType.json);
      await expectInverse(['foo'], PgDataType.json);
      await expectInverse({
        'key': 'val',
        'key1': 1,
        'array': ['foo']
      }, PgDataType.json);

      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:json)',
            substitutionValues: {'v': DateTime.now()});
        fail('unreachable');
      } on JsonUnsupportedObjectError catch (_) {}
    });

    test('point', () async {
      await expectInverse(PgPoint(0, 0), PgDataType.point);
      await expectInverse(PgPoint(100, 123.456), PgDataType.point);
      await expectInverse(PgPoint(0.001, -999), PgDataType.point);

      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:point)',
            substitutionValues: {'v': 'text'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: PgPoint'));
      }
    });

    test('booleanArray', () async {
      await expectInverse(<bool>[], PgDataType.booleanArray);
      await expectInverse([false, true], PgDataType.booleanArray);
      await expectInverse([true], PgDataType.booleanArray);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:_bool)',
            substitutionValues: {'v': 'not-list-bool'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: List<bool>'));
      }
    });

    test('integerArray', () async {
      await expectInverse(<int>[], PgDataType.integerArray);
      await expectInverse([-1, 0, 200], PgDataType.integerArray);
      await expectInverse([-123], PgDataType.integerArray);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:_int4)',
            substitutionValues: {'v': 'not-list-int'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: List<int>'));
      }
    });

    test('bigIntegerArray', () async {
      await expectInverse(<int>[], PgDataType.bigIntegerArray);
      await expectInverse([-1, 0, 200], PgDataType.bigIntegerArray);
      await expectInverse([-123], PgDataType.bigIntegerArray);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:_int8)',
            substitutionValues: {'v': 'not-list-int'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: List<int>'));
      }
    });

    test('doubleArray', () async {
      await expectInverse(<double>[], PgDataType.doubleArray);
      await expectInverse([-123.0, 0.0, 1.0], PgDataType.doubleArray);
      await expectInverse([0.001, 45.678], PgDataType.doubleArray);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:_float8)',
            substitutionValues: {'v': 'not-list-double'});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: List<double>'));
      }
    });

    test('varCharArray', () async {
      await expectInverse(<String>[], PgDataType.varCharArray);
      await expectInverse(['', 'foo', 'foo\n'], PgDataType.varCharArray);
      await expectInverse(['foo\nbar;s', '"\'"'], PgDataType.varCharArray);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:_varchar(10))',
            substitutionValues: {'v': 0});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: List<String>'));
      }
    });

    test('textArray', () async {
      await expectInverse(<String>[], PgDataType.textArray);
      await expectInverse(['', 'foo', 'foo\n'], PgDataType.textArray);
      await expectInverse(['foo\nbar;s', '"\'"'], PgDataType.textArray);
      try {
        await conn.query('INSERT INTO t (v) VALUES (@v:_text)',
            substitutionValues: {'v': 0});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains('Expected: List<String>'));
      }
    });

    test('jsonbArray', () async {
      await expectInverse(['string', 2, 0.1], PgDataType.jsonbArray);
      await expectInverse([
        1,
        {},
        {'a': 'b'}
      ], PgDataType.jsonbArray);
      await expectInverse([
        ['foo'],
        [
          1,
          {
            'a': ['b']
          }
        ]
      ], PgDataType.jsonbArray);
      await expectInverse([
        {
          'key': 'val',
          'key1': 1,
          'array': ['foo']
        }
      ], PgDataType.jsonbArray);

      try {
        await conn
            .query('INSERT INTO t (v) VALUES (@v:_jsonb)', substitutionValues: {
          'v': [DateTime.now()]
        });
        fail('unreachable');
      } on JsonUnsupportedObjectError catch (_) {}
    });

    test('void', () async {
      final result = await conn.query('SELECT NULL::void AS r');
      expect(result.columnDescriptions, [
        isA<ColumnDescription>()
            .having((e) => e.typeId, 'typeId', PgDataType.voidType.oid)
      ]);

      expect(result, [
        [null]
      ]);

      expect(
        () => PostgresBinaryEncoder(PgDataType.voidType).convert(1, utf8),
        throwsArgumentError,
      );
    });

    test('regtype', () async {
      await expectInverse(PgDataType.bigInteger, PgDataType.regtype);
      await expectInverse(PgDataType.voidType, PgDataType.regtype);
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
      } on PostgreSQLException catch (e) {
        expect(e.toString(), contains('Could not infer type'));
      }
    });
  });

  test('Invalid UUID encoding', () {
    final converter = PostgresBinaryEncoder<Object>(PgDataType.uuid);
    try {
      converter.convert('z0000000-0000-0000-0000-000000000000', utf8);
      fail('unreachable');
    } on FormatException catch (e) {
      expect(e.toString(), contains('Invalid UUID string'));
    }

    try {
      converter.convert(123123, utf8);
      fail('unreachable');
    } on FormatException catch (e) {
      expect(e.toString(), contains('Invalid type for parameter'));
    }

    try {
      converter.convert('0000000-0000-0000-0000-000000000000', utf8);
      fail('unreachable');
    } on FormatException catch (e) {
      expect(e.toString(), contains('Invalid UUID string'));
    }

    try {
      converter.convert('00000000-0000-0000-0000-000000000000f', utf8);
      fail('unreachable');
    } on FormatException catch (e) {
      expect(e.toString(), contains('Invalid UUID string'));
    }
  });
}

Future expectInverse(dynamic value, PgDataType dataType) async {
  final type = PostgreSQLFormat.dataTypeStringForDataType(dataType);

  await conn.execute('CREATE TEMPORARY TABLE IF NOT EXISTS t (v $type)');
  final result = await conn.query(
      'INSERT INTO t (v) VALUES (${PostgreSQLFormat.id('v', type: dataType)}) RETURNING v',
      substitutionValues: {'v': value});
  expect(result.first.first, equals(value));

  final encoder = PostgresBinaryEncoder(dataType);
  final encodedValue = encoder.convert(value, utf8);

  if (dataType == PgDataType.serial) {
    dataType = PgDataType.integer;
  } else if (dataType == PgDataType.bigSerial) {
    dataType = PgDataType.bigInteger;
  }

  final decoder = PostgresBinaryDecoder(dataType);
  final decodedValue = decoder.convert(encodedValue, utf8);

  expect(decodedValue, value);
}
