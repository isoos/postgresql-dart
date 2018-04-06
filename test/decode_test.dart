import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  PostgreSQLConnection connection;
  setUp(() async {
    connection = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");
    await connection.open();

    await connection.execute("""
        CREATE TEMPORARY TABLE t (
          i int, s serial, bi bigint, bs bigserial, bl boolean, si smallint, 
          t text, f real, d double precision, dt date, ts timestamp, tsz timestamptz, j jsonb, ba bytea,
          u uuid)
    """);

    await connection.execute("INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz, j, ba, u) "
        "VALUES (-2147483648, -9223372036854775808, TRUE, -32768, "
        "'string', 10.0, 10.0, '1983-11-06', "
        "'1983-11-06 06:00:00.000000', '1983-11-06 06:00:00.000000', "
        "'{\"key\":\"value\"}', E'\\\\000', '00000000-0000-0000-0000-000000000000')");
    await connection.execute("INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz, j, ba, u) "
        "VALUES (2147483647, 9223372036854775807, FALSE, 32767, "
        "'a significantly longer string to the point where i doubt this actually matters', "
        "10.25, 10.125, '2183-11-06', '2183-11-06 00:00:00.111111', "
        "'2183-11-06 00:00:00.999999', "
        "'[{\"key\":1}]', E'\\\\377', 'FFFFFFFF-ffff-ffff-ffff-ffffffffffff')");

    await connection.execute("INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz, j, ba, u) "
        "VALUES (null, null, null, null, null, null, null, null, null, null, null, null, null)");
  });
  tearDown(() async {
    await connection?.close();
  });

  test("Fetch em", () async {
    var res = await connection.query("select * from t");

    var row1 = res[0];
    var row2 = res[1];
    var row3 = res[2];

    // lower bound row
    expect(row1[0], equals(-2147483648));
    expect(row1[1], equals(1));
    expect(row1[2], equals(-9223372036854775808));
    expect(row1[3], equals(1));
    expect(row1[4], equals(true));
    expect(row1[5], equals(-32768));
    expect(row1[6], equals("string"));
    expect(row1[7] is double, true);
    expect(row1[7], equals(10.0));
    expect(row1[8] is double, true);
    expect(row1[8], equals(10.0));
    expect(row1[9], equals(new DateTime.utc(1983, 11, 6)));
    expect(row1[10], equals(new DateTime.utc(1983, 11, 6, 6)));
    expect(row1[11], equals(new DateTime.utc(1983, 11, 6, 6)));
    expect(row1[12], equals({"key": "value"}));
    expect(row1[13], equals([0]));
    expect(row1[14], equals("00000000-0000-0000-0000-000000000000"));

    // upper bound row
    expect(row2[0], equals(2147483647));
    expect(row2[1], equals(2));
    expect(row2[2], equals(9223372036854775807));
    expect(row2[3], equals(2));
    expect(row2[4], equals(false));
    expect(row2[5], equals(32767));
    expect(row2[6], equals("a significantly longer string to the point where i doubt this actually matters"));
    expect(row2[7] is double, true);
    expect(row2[7], equals(10.25));
    expect(row2[8] is double, true);
    expect(row2[8], equals(10.125));
    expect(row2[9], equals(new DateTime.utc(2183, 11, 6)));
    expect(row2[10], equals(new DateTime.utc(2183, 11, 6, 0, 0, 0, 111, 111)));
    expect(row2[11], equals(new DateTime.utc(2183, 11, 6, 0, 0, 0, 999, 999)));
    expect(
        row2[12],
        equals([
          {"key": 1}
        ]));
    expect(row2[13], equals([255]));
    expect(row2[14], equals("ffffffff-ffff-ffff-ffff-ffffffffffff"));


    // all null row
    expect(row3[0], isNull);
    expect(row3[1], equals(3));
    expect(row3[2], isNull);
    expect(row3[3], equals(3));
    expect(row3[4], isNull);
    expect(row3[5], isNull);
    expect(row3[6], isNull);
    expect(row3[7], isNull);
    expect(row3[8], isNull);
    expect(row3[9], isNull);
    expect(row3[10], isNull);
    expect(row3[11], isNull);
    expect(row3[12], isNull);
    expect(row3[13], isNull);
    expect(row3[14], isNull);
  });

  test("Fetch/insert empty string", () async {
    await connection.execute("CREATE TEMPORARY TABLE u (t text)");
    var results =
        await connection.query("INSERT INTO u (t) VALUES (@t:text) returning t", substitutionValues: {"t": ""});
    expect(results, [
      [""]
    ]);

    results = await connection.query("select * from u");
    expect(results, [
      [""]
    ]);
  });

  test("Fetch/insert null value", () async {
    await connection.execute("CREATE TEMPORARY TABLE u (t text)");
    var results =
        await connection.query("INSERT INTO u (t) VALUES (@t:text) returning t", substitutionValues: {"t": null});
    expect(results, [
      [null]
    ]);

    results = await connection.query("select * from u");
    expect(results, [
      [null]
    ]);
  });
}
