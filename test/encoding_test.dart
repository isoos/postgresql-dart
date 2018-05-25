import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';

import 'package:postgres/postgres.dart';
import 'package:postgres/src/binary_codec.dart';
import 'package:postgres/src/text_codec.dart';
import 'package:postgres/src/types.dart';
import 'package:postgres/src/utf8_backed_string.dart';

PostgreSQLConnection conn;

void main() {
  group("Binary encoders", () {
    setUp(() async {
      conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");
      await conn.open();
    });

    tearDown(() async {
      await conn.close();
      conn = null;
    });

    // expectInverse ensures that:
    // 1. encoder/decoder is reversible
    // 2. can actually encode and decode a real pg query
    // it also creates a table named t with column v of type being tested
    test("bool", () async {
      await expectInverse(true, PostgreSQLDataType.boolean);
      await expectInverse(false, PostgreSQLDataType.boolean);
      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:boolean)", substitutionValues: {"v": "not-bool"});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains("Expected: bool"));
      }
    });

    test("smallint", () async {
      await expectInverse(-1, PostgreSQLDataType.smallInteger);
      await expectInverse(0, PostgreSQLDataType.smallInteger);
      await expectInverse(1, PostgreSQLDataType.smallInteger);
      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:int2)", substitutionValues: {"v": "not-int2"});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains("Expected: int"));
      }
    });

    test("integer", () async {
      await expectInverse(-1, PostgreSQLDataType.integer);
      await expectInverse(0, PostgreSQLDataType.integer);
      await expectInverse(1, PostgreSQLDataType.integer);
      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:int4)", substitutionValues: {"v": "not-int4"});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains("Expected: int"));
      }
    });

    test("serial", () async {
      await expectInverse(0, PostgreSQLDataType.serial);
      await expectInverse(1, PostgreSQLDataType.serial);
      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:int4)", substitutionValues: {"v": "not-serial"});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains("Expected: int"));
      }

    });

    test("bigint", () async {
      await expectInverse(-1, PostgreSQLDataType.bigInteger);
      await expectInverse(0, PostgreSQLDataType.bigInteger);
      await expectInverse(1, PostgreSQLDataType.bigInteger);
      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:int8)", substitutionValues: {"v": "not-int8"});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains("Expected: int"));
      }

    });

    test("bigserial", () async {
      await expectInverse(0, PostgreSQLDataType.bigSerial);
      await expectInverse(1, PostgreSQLDataType.bigSerial);
      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:int8)", substitutionValues: {"v": "not-bigserial"});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains("Expected: int"));
      }

    });

    test("text", () async {
      await expectInverse("", PostgreSQLDataType.text);
      await expectInverse("foo", PostgreSQLDataType.text);
      await expectInverse("foo\n", PostgreSQLDataType.text);
      await expectInverse("foo\nbar;s", PostgreSQLDataType.text);
      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:text)", substitutionValues: {"v": 0});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains("Expected: String"));
      }
    });

    test("real", () async {
      await expectInverse(-1.0, PostgreSQLDataType.real);
      await expectInverse(0.0, PostgreSQLDataType.real);
      await expectInverse(1.0, PostgreSQLDataType.real);
      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:float4)", substitutionValues: {"v": "not-real"});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains("Expected: double"));
      }
    });

    test("double", () async {
      await expectInverse(-1.0, PostgreSQLDataType.double);
      await expectInverse(0.0, PostgreSQLDataType.double);
      await expectInverse(1.0, PostgreSQLDataType.double);
      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:float8)", substitutionValues: {"v": "not-double"});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains("Expected: double"));
      }
    });

    test("date", () async {
      await expectInverse(new DateTime.utc(1920, 10, 1), PostgreSQLDataType.date);
      await expectInverse(new DateTime.utc(2120, 10, 5), PostgreSQLDataType.date);
      await expectInverse(new DateTime.utc(2016, 10, 1), PostgreSQLDataType.date);
      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:date)", substitutionValues: {"v": "not-date"});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains("Expected: DateTime"));
      }
    });

    test("timestamp", () async {
      await expectInverse(new DateTime.utc(1920, 10, 1), PostgreSQLDataType.timestampWithoutTimezone);
      await expectInverse(new DateTime.utc(2120, 10, 5), PostgreSQLDataType.timestampWithoutTimezone);
      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:timestamp)", substitutionValues: {"v": "not-timestamp"});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains("Expected: DateTime"));
      }
    });

    test("timestamptz", () async {
      await expectInverse(new DateTime.utc(1920, 10, 1), PostgreSQLDataType.timestampWithTimezone);
      await expectInverse(new DateTime.utc(2120, 10, 5), PostgreSQLDataType.timestampWithTimezone);
      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:timestamptz)", substitutionValues: {"v": "not-timestamptz"});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains("Expected: DateTime"));
      }
    });

    test("jsonb", () async {
      await expectInverse("string", PostgreSQLDataType.json);
      await expectInverse(2, PostgreSQLDataType.json);
      await expectInverse(["foo"], PostgreSQLDataType.json);
      await expectInverse({
        "key": "val",
        "key1": 1,
        "array": ["foo"]
      }, PostgreSQLDataType.json);

      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:jsonb)", substitutionValues: {"v": new DateTime.now()});
        fail('unreachable');
      } on JsonUnsupportedObjectError catch (_) {}
    });

    test("bytea", () async {
      await expectInverse([0], PostgreSQLDataType.byteArray);
      await expectInverse([1,2,3,4,5], PostgreSQLDataType.byteArray);
      await expectInverse([255, 254, 253], PostgreSQLDataType.byteArray);

      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:bytea)", substitutionValues: {"v": new DateTime.now()});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains("Expected: List<int>"));
      }
    });

    test("uuid", () async {
      await expectInverse("00000000-0000-0000-0000-000000000000", PostgreSQLDataType.uuid);
      await expectInverse("12345678-abcd-efab-cdef-012345678901", PostgreSQLDataType.uuid);

      try {
        await conn.query("INSERT INTO t (v) VALUES (@v:uuid)", substitutionValues: {"v": new DateTime.now()});
        fail('unreachable');
      } on FormatException catch (e) {
        expect(e.toString(), contains("Expected: String"));
      }
    });
  });

  group("Text encoders", () {
    test("Escape strings", () {
      final encoder = new PostgresTextEncoder(true);
      //                                                       '   b   o    b   '
      expect(utf8.encode(encoder.convert('bob')), equals([39, 98, 111, 98, 39]));

      //                                                         '   b   o   \n   b   '
      expect(utf8.encode(encoder.convert('bo\nb')), equals([39, 98, 111, 10, 98, 39]));

      //                                                         '   b   o   \r   b   '
      expect(utf8.encode(encoder.convert('bo\rb')), equals([39, 98, 111, 13, 98, 39]));

      //                                                         '   b   o  \b   b   '
      expect(utf8.encode(encoder.convert('bo\bb')), equals([39, 98, 111, 8, 98, 39]));

      //                                                     '   '   '   '
      expect(utf8.encode(encoder.convert("'")), equals([39, 39, 39, 39]));

      //                                                      '   '   '   '   '   '
      expect(utf8.encode(encoder.convert("''")), equals([39, 39, 39, 39, 39, 39]));

      //                                                       '   '   '   '   '   '
      expect(utf8.encode(encoder.convert("\''")), equals([39, 39, 39, 39, 39, 39]));

      //                                                       sp   E   '   \   \   '   '   '   '   '
      expect(utf8.encode(encoder.convert("\\''")), equals([32, 69, 39, 92, 92, 39, 39, 39, 39, 39]));

      //                                                      sp   E   '   \   \   '   '   '
      expect(utf8.encode(encoder.convert("\\'")), equals([32, 69, 39, 92, 92, 39, 39, 39]));
    });

    test("Encode DateTime", () {
      // Get users current timezone
      var tz = new DateTime(2001, 2, 3).timeZoneOffset;
      var tzOffsetDelimiter = "${tz.isNegative ? '-' : '+'}"
          "${tz
        .abs()
        .inHours
        .toString()
        .padLeft(2, '0')}"
          ":${(tz.inSeconds % 60).toString().padLeft(2, '0')}";

      var pairs = {
        "2001-02-03T00:00:00.000$tzOffsetDelimiter": new DateTime(2001, DateTime.february, 3),
        "2001-02-03T04:05:06.000$tzOffsetDelimiter": new DateTime(2001, DateTime.february, 3, 4, 5, 6, 0),
        "2001-02-03T04:05:06.999$tzOffsetDelimiter": new DateTime(2001, DateTime.february, 3, 4, 5, 6, 999),
        "0010-02-03T04:05:06.123$tzOffsetDelimiter BC": new DateTime(-10, DateTime.february, 3, 4, 5, 6, 123),
        "0010-02-03T04:05:06.000$tzOffsetDelimiter BC": new DateTime(-10, DateTime.february, 3, 4, 5, 6, 0),
        "012345-02-03T04:05:06.000$tzOffsetDelimiter BC": new DateTime(-12345, DateTime.february, 3, 4, 5, 6, 0),
        "012345-02-03T04:05:06.000$tzOffsetDelimiter": new DateTime(12345, DateTime.february, 3, 4, 5, 6, 0)
      };

      final encoder = new PostgresTextEncoder(false);
      pairs.forEach((k, v) {
        expect(encoder.convert(v), "'$k'");
      });
    });

    test("Encode Double", () {
      var pairs = {
        "'nan'": double.nan,
        "'infinity'": double.infinity,
        "'-infinity'": double.negativeInfinity,
        "1.7976931348623157e+308": double.maxFinite,
        "5e-324": double.minPositive,
        "-0.0": -0.0,
        "0.0": 0.0
      };

      final encoder = new PostgresTextEncoder(false);
      pairs.forEach((k, v) {
        expect(encoder.convert(v), "$k");
      });
    });

    test("Encode Int", () {
      final encoder = new PostgresTextEncoder(false);

      expect(encoder.convert(1), "1");
      expect(encoder.convert(1234324323), "1234324323");
      expect(encoder.convert(-1234324323), "-1234324323");
    });

    test("Encode Bool", () {
      final encoder = new PostgresTextEncoder(false);

      expect(encoder.convert(true), "TRUE");
      expect(encoder.convert(false), "FALSE");
    });

    test("Encode JSONB", () {
      final encoder = new PostgresTextEncoder(false);

      expect(encoder.convert({"a": "b"}), "{\"a\":\"b\"}");
      expect(encoder.convert({"a": true}), "{\"a\":true}");
      expect(encoder.convert({"b": false}), "{\"b\":false}");
    });

    test("Attempt to infer unknown type throws exception", () {
      final encoder = new PostgresTextEncoder(false);
      try {
        encoder.convert([]);
        fail('unreachable');
      } on PostgreSQLException catch (e) {
        expect(e.toString(), contains("Could not infer type"));
      }
    });
  });

  test("UTF8String caches string regardless of which method is called first", () {
    var u = new UTF8BackedString("abcd");
    var v = new UTF8BackedString("abcd");

    u.utf8Length;
    v.utf8Bytes;

    expect(u.hasCachedBytes, true);
    expect(v.hasCachedBytes, true);
  });

  test("Invalid UUID encoding", () {
    final converter = new PostgresBinaryEncoder(PostgreSQLDataType.uuid);
    try {
      converter.convert("z0000000-0000-0000-0000-000000000000");
      fail('unreachable');
    } on FormatException catch (e) {
      expect(e.toString(), contains("Invalid UUID string"));
    }

    try {
      converter.convert(123123);
      fail('unreachable');
    } on FormatException catch (e) {
      expect(e.toString(), contains("Invalid type for parameter"));
    }

    try {
      converter.convert("0000000-0000-0000-0000-000000000000");
      fail('unreachable');
    } on FormatException catch (e) {
      expect(e.toString(), contains("Invalid UUID string"));
    }

    try {
      converter.convert("00000000-0000-0000-0000-000000000000f");
      fail('unreachable');
    } on FormatException catch (e) {
      expect(e.toString(), contains("Invalid UUID string"));
    }
  });
}

Future expectInverse(dynamic value, PostgreSQLDataType dataType) async {
  final type = PostgreSQLFormat.dataTypeStringForDataType(dataType);

  await conn.execute("CREATE TEMPORARY TABLE IF NOT EXISTS t (v $type)");
  final result = await conn.query("INSERT INTO t (v) VALUES (${PostgreSQLFormat.id("v", type: dataType)}) RETURNING v", substitutionValues: {
    "v": value
  });
  expect(result.first.first, equals(value));

  final encoder = new PostgresBinaryEncoder(dataType);
  final encodedValue = encoder.convert(value);

  if (dataType == PostgreSQLDataType.serial) {
    dataType = PostgreSQLDataType.integer;
  } else if (dataType == PostgreSQLDataType.bigSerial) {
    dataType = PostgreSQLDataType.bigInteger;
  }
  var code;
  PostgresBinaryDecoder.typeMap.forEach((key, type) {
    if (type == dataType) {
      code = key;
    }
  });

  final decoder = new PostgresBinaryDecoder(code);
  final decodedValue = decoder.convert(encodedValue);

  expect(decodedValue, value);
}
