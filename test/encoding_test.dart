import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test("Escape strings", () {
    expect(PostgreSQLCodec.encode('bob'), equals("E'bob'"));
    expect(PostgreSQLCodec.encode('bo\nb'), equals(r"E'bo\nb'"));
    expect(PostgreSQLCodec.encode('bo\rb'), equals(r"E'bo\rb'"));
    expect(PostgreSQLCodec.encode(r'bo\b'), equals(r"E'bo\\b'"));

    expect(PostgreSQLCodec.encode(r"'"), equals(r"E'\''"));
    expect(PostgreSQLCodec.encode(r" '' "), equals(r"E' \'\' '"));
    expect(PostgreSQLCodec.encode(r"\''"), equals(r"E'\\\'\''"));
  });

  test("Encode DateTime", () {
    // Get users current timezone
    var tz = new DateTime(2001, 2, 3).timeZoneOffset;
    var tzOffsetDelimiter = "${tz.isNegative ? '-' : '+'}"
        "${tz.abs().inHours.toString().padLeft(2, '0')}"
        ":${(tz.inSeconds % 60).toString().padLeft(2, '0')}";

    var pairs = {
      "2001-02-03T00:00:00.000$tzOffsetDelimiter" : new DateTime(2001, DateTime.FEBRUARY, 3),
      "2001-02-03T04:05:06.000$tzOffsetDelimiter" : new DateTime(2001, DateTime.FEBRUARY, 3, 4, 5, 6, 0),
      "2001-02-03T04:05:06.999$tzOffsetDelimiter" : new DateTime(2001, DateTime.FEBRUARY, 3, 4, 5, 6, 999),
      "0010-02-03T04:05:06.123$tzOffsetDelimiter BC" : new DateTime(-10, DateTime.FEBRUARY, 3, 4, 5, 6, 123),
      "0010-02-03T04:05:06.000$tzOffsetDelimiter BC" : new DateTime(-10, DateTime.FEBRUARY, 3, 4, 5, 6, 0),
      "012345-02-03T04:05:06.000$tzOffsetDelimiter BC" : new DateTime(-12345, DateTime.FEBRUARY, 3, 4, 5, 6, 0),
      "012345-02-03T04:05:06.000$tzOffsetDelimiter" : new DateTime(12345, DateTime.FEBRUARY, 3, 4, 5, 6, 0)
    };

    pairs.forEach((k, v) {
      expect(PostgreSQLCodec.encode(v), "'$k'");
    });
  });

  test("Encode Double", () {
    var pairs = {
      "'nan'" : double.NAN,
      "'infinity'" : double.INFINITY,
      "'-infinity'" : double.NEGATIVE_INFINITY,
      "1.7976931348623157e+308" : double.MAX_FINITE,
      "5e-324" : double.MIN_POSITIVE,
      "-0.0" : -0.0,
      "0.0" : 0.0
    };

    pairs.forEach((k, v) {
      expect(PostgreSQLCodec.encode(v), "$k");
      expect(PostgreSQLCodec.encode(v, dataType: PostgreSQLDataType.real), "$k");
      expect(PostgreSQLCodec.encode(v, dataType: PostgreSQLDataType.double), "$k");
    });

    expect(PostgreSQLCodec.encode(1, dataType: PostgreSQLDataType.double), "1");

    expect(PostgreSQLCodec.encode(null, dataType: PostgreSQLDataType.real), "null");
    expect(PostgreSQLCodec.encode(null, dataType: PostgreSQLDataType.double), "null");
  });

  test("Encode Int", () {
    expect(PostgreSQLCodec.encode(1.0, dataType: PostgreSQLDataType.integer), "1");

    expect(PostgreSQLCodec.encode(1), "1");
    expect(PostgreSQLCodec.encode(1, dataType: PostgreSQLDataType.integer), "1");
    expect(PostgreSQLCodec.encode(1, dataType: PostgreSQLDataType.bigInteger), "1");
    expect(PostgreSQLCodec.encode(1, dataType: PostgreSQLDataType.smallInteger), "1");


    expect(PostgreSQLCodec.encode(null, dataType: PostgreSQLDataType.integer), "null");
    expect(PostgreSQLCodec.encode(null, dataType: PostgreSQLDataType.bigInteger), "null");
    expect(PostgreSQLCodec.encode(null, dataType: PostgreSQLDataType.smallInteger), "null");
  });

  test("Encode Bool", () {
    expect(PostgreSQLCodec.encode(null, dataType: PostgreSQLDataType.boolean), "null");
    expect(PostgreSQLCodec.encode(true), "TRUE");
    expect(PostgreSQLCodec.encode(false), "FALSE");
    expect(PostgreSQLCodec.encode(true, dataType: PostgreSQLDataType.boolean), "TRUE");
    expect(PostgreSQLCodec.encode(false, dataType: PostgreSQLDataType.boolean), "FALSE");
  });
}