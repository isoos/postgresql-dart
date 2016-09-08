import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  group("Successful queries", () {
    var connection = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");

    setUp(() async {
      connection = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");
      await connection.open();
      await connection.execute("CREATE TEMPORARY TABLE t (i int, s serial, bi bigint, bs bigserial, bl boolean, si smallint, t text, f real, d double precision, dt date, ts timestamp, tsz timestamptz)");
      await connection.execute("CREATE TEMPORARY TABLE u (i1 int not null, i2 int not null);");
      await connection.execute("CREATE TEMPORARY TABLE n (i1 int, i2 int not null);");
    });

    tearDown(() async {
      await connection.close();
    });

    test("Query without specifying types", () async {
      var result = await connection.query("INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz) values "
          "(${PostgreSQLFormat.id("i")},"
          "${PostgreSQLFormat.id("bi")},"
          "${PostgreSQLFormat.id("bl")},"
          "${PostgreSQLFormat.id("si")},"
          "${PostgreSQLFormat.id("t")},"
          "${PostgreSQLFormat.id("f")},"
          "${PostgreSQLFormat.id("d")},"
          "${PostgreSQLFormat.id("dt")},"
          "${PostgreSQLFormat.id("ts")},"
          "${PostgreSQLFormat.id("tsz")}) returning i,s, bi, bs, bl, si, t, f, d, dt, ts, tsz",
          substitutionValues: {
            "i" : 1,
            "bi" : 2,
            "bl" : true,
            "si" : 3,
            "t" : "foobar",
            "f" : 5.0,
            "d" : 6.0,
            "dt" : new DateTime.utc(2000),
            "ts" : new DateTime.utc(2000, 2),
            "tsz" : new DateTime.utc(2000, 3),
          });

      var expectedRow = [1, 1, 2, 1, true, 3, "foobar", 5.0, 6.0, new DateTime.utc(2000), new DateTime.utc(2000, 2), new DateTime.utc(2000, 3)];
      expect(result, [expectedRow]);
      result = await connection.query("select i,s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t");
      expect(result, [expectedRow]);
    });

    test("Query by specifying all types", () async {
      var result = await connection.query("INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz) values "
          "(${PostgreSQLFormat.id("i", type: PostgreSQLDataType.integer)},"
          "${PostgreSQLFormat.id("bi", type: PostgreSQLDataType.bigInteger)},"
          "${PostgreSQLFormat.id("bl", type: PostgreSQLDataType.boolean)},"
          "${PostgreSQLFormat.id("si", type: PostgreSQLDataType.smallInteger)},"
          "${PostgreSQLFormat.id("t", type: PostgreSQLDataType.text)},"
          "${PostgreSQLFormat.id("f", type: PostgreSQLDataType.real)},"
          "${PostgreSQLFormat.id("d", type: PostgreSQLDataType.double)},"
          "${PostgreSQLFormat.id("dt", type: PostgreSQLDataType.date)},"
          "${PostgreSQLFormat.id("ts", type: PostgreSQLDataType.timestampWithoutTimezone)},"
          "${PostgreSQLFormat.id("tsz", type: PostgreSQLDataType.timestampWithTimezone)}) returning i,s, bi, bs, bl, si, t, f, d, dt, ts, tsz",
          substitutionValues: {
            "i" : 1,
            "bi" : 2,
            "bl" : true,
            "si" : 3,
            "t" : "foobar",
            "f" : 5.0,
            "d" : 6.0,
            "dt" : new DateTime.utc(2000),
            "ts" : new DateTime.utc(2000, 2),
            "tsz" : new DateTime.utc(2000, 3),
          });

      var expectedRow = [1, 1, 2, 1, true, 3, "foobar", 5.0, 6.0, new DateTime.utc(2000), new DateTime.utc(2000, 2), new DateTime.utc(2000, 3)];
      expect(result, [expectedRow]);

      result = await connection.query("select i,s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t");
      expect(result, [expectedRow]);
    });

    test("Query by specifying some types", () async {
      var result = await connection.query("INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz) values "
          "(${PostgreSQLFormat.id("i")},"
          "${PostgreSQLFormat.id("bi", type: PostgreSQLDataType.bigInteger)},"
          "${PostgreSQLFormat.id("bl")},"
          "${PostgreSQLFormat.id("si", type: PostgreSQLDataType.smallInteger)},"
          "${PostgreSQLFormat.id("t")},"
          "${PostgreSQLFormat.id("f", type: PostgreSQLDataType.real)},"
          "${PostgreSQLFormat.id("d")},"
          "${PostgreSQLFormat.id("dt", type: PostgreSQLDataType.date)},"
          "${PostgreSQLFormat.id("ts")},"
          "${PostgreSQLFormat.id("tsz", type: PostgreSQLDataType.timestampWithTimezone)}) returning i,s, bi, bs, bl, si, t, f, d, dt, ts, tsz",
          substitutionValues: {
            "i" : 1,
            "bi" : 2,
            "bl" : true,
            "si" : 3,
            "t" : "foobar",
            "f" : 5.0,
            "d" : 6.0,
            "dt" : new DateTime.utc(2000),
            "ts" : new DateTime.utc(2000, 2),
            "tsz" : new DateTime.utc(2000, 3),
          });

      var expectedRow = [1, 1, 2, 1, true, 3, "foobar", 5.0, 6.0, new DateTime.utc(2000), new DateTime.utc(2000, 2), new DateTime.utc(2000, 3)];
      expect(result, [expectedRow]);
      result = await connection.query("select i,s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t");
      expect(result, [expectedRow]);
    });

    test("Can supply null for values (binary)", () async {
      var results = await connection.query("INSERT INTO n (i1, i2) values (@i1:int4, @i2:int4) returning i1, i2", substitutionValues: {
        "i1" : null,
        "i2" : 1,
      });

      expect(results, [[null, 1]]);
    });

    test("Can supply null for values (text)", () async {
      var results = await connection.query("INSERT INTO n (i1, i2) values (@i1, @i2:int4) returning i1, i2", substitutionValues: {
        "i1" : null,
        "i2" : 1,
      });

      expect(results, [[null, 1]]);
    });

    test("Overspecifying parameters does not impact query (text)", () async {
      var results = await connection.query("INSERT INTO u (i1, i2) values (@i1, @i2) returning i1, i2", substitutionValues: {
        "i1" : 0,
        "i2" : 1,
        "i3" : 0,
      });

      expect(results, [[0, 1]]);
    });

    test("Overspecifying parameters does not impact query (binary)", () async {
      var results = await connection.query("INSERT INTO u (i1, i2) values (@i1:int4, @i2:int4) returning i1, i2", substitutionValues: {
        "i1" : 0,
        "i2" : 1,
        "i3" : 0,
      });

      expect(results, [[0, 1]]);
    });
  });

  group("Unsuccesful queries", () {
    var connection = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");

    setUp(() async {
      connection = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");
      await connection.open();
      await connection.execute("CREATE TEMPORARY TABLE t (i1 int not null, i2 int not null)");
    });

    tearDown(() async {
      await connection.close();
    });

    test("A query that fails on the server will report back an exception through the query method", () async {
      try {
        await connection.query("INSERT INTO t (i1) values (@i1)", substitutionValues: {
          "i1" : 0
        });
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.severity, PostgreSQLSeverity.error);
        expect(e.message, contains("null value in column \"i2\""));
      }
    });

    test("Not enough parameters to support format string throws error prior to sending to server", () async {
      try {
        await connection.query("INSERT INTO t (i1) values (@i1)", substitutionValues: {});
        expect(true, false);
      } on PostgreSQLFormatException catch (e) {
        expect(e.message, contains("Format string specified identifier with name i1"));
      }

      try {
        await connection.query("INSERT INTO t (i1) values (@i1)");
        expect(true, false);
      } on PostgreSQLFormatException catch (e) {
        expect(e.message, contains("Format string specified identifier with name i1"));
      }
    });
  });
}