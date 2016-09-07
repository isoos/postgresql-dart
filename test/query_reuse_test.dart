import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

String sid(String id, PostgreSQLDataType dt) => PostgreSQLFormat.id(id, type: dt);

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

    test("Call query multiple times with supplied parameter data succeeds", () async {
      var insertQueryString = "INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz) VALUES "
          "(${sid("i", PostgreSQLDataType.integer)}, ${sid("bi", PostgreSQLDataType.bigInteger)},"
          "${sid("bl", PostgreSQLDataType.boolean)}, ${sid("si", PostgreSQLDataType.smallInteger)},"
          "${sid("t", PostgreSQLDataType.text)}, ${sid("f", PostgreSQLDataType.real)},"
          "${sid("d", PostgreSQLDataType.double)}, ${sid("dt", PostgreSQLDataType.date)},"
          "${sid("ts", PostgreSQLDataType.timestampWithoutTimezone)}, ${sid("tsz", PostgreSQLDataType.timestampWithoutTimezone)}"
          ") returning i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz";
      var results = await connection.query(insertQueryString, substitutionValues: {
        "i" : 1,
        "bi" : 2,
        "bl" : true,
        "si" : 3,
        "t" : "foobar",
        "f" : 5.0,
        "d" : 6.0,
        "dt" : new DateTime.utc(2000),
        "ts" : new DateTime.utc(2000, 2),
        "tsz" : new DateTime.utc(2000, 3)
      });

      var expectedRow1 = [1, 1, 2, 1, true, 3, "foobar", 5.0, 6.0, new DateTime.utc(2000), new DateTime.utc(2000, 2), new DateTime.utc(2000, 3)];
      expect(results, [expectedRow1]);

      results = await connection.query(insertQueryString, substitutionValues: {
        "i" : 2,
        "bi" : 3,
        "bl" : false,
        "si" : 4,
        "t" : "barfoo",
        "f" : 6.0,
        "d" : 7.0,
        "dt" : new DateTime.utc(2001),
        "ts" : new DateTime.utc(2001, 2),
        "tsz" : new DateTime.utc(2001, 3)
      });

      var expectedRow2 = [2, 2, 3, 2, false, 4, "barfoo", 6.0, 7.0, new DateTime.utc(2001), new DateTime.utc(2001, 2), new DateTime.utc(2001, 3)];
      expect(results, [expectedRow2]);

      results = await connection.query("select i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t");
      expect(results, [expectedRow1, expectedRow2]);

      results = await connection.query("select i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t");
      expect(results, [expectedRow1, expectedRow2]);

      results = await connection.query("select i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t where i < @i", substitutionValues: {
        "i" : 0
      });
      expect(results, []);

      results = await connection.query("select i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t where i < @i", substitutionValues: {
        "i" : 2
      });
      expect(results, [expectedRow1]);

      results = await connection.query("select i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t where i < @i", substitutionValues: {
        "i" : 5
      });
      expect(results, [expectedRow1, expectedRow2]);
    });

    test("Call query multiple times with supplied parameter data succeeds", () async {
      var insertQueryString = "INSERT INTO u (i1, i2) VALUES (@i1, @i2) returning i1, i2";
      var results = await connection.query(insertQueryString, substitutionValues: {
        "i1" : 1,
        "i2" : 2,
      });

      var expectedRow1 = [1, 2];
      expect(results, [expectedRow1]);

      results = await connection.query(insertQueryString, substitutionValues: {
        "i1" : 3,
        "i2" : 4,
      });

      var expectedRow2 = [3, 4];
      expect(results, [expectedRow2]);

      results = await connection.query("select i1, i2 from u");
      expect(results, [expectedRow1, expectedRow2]);

      results = await connection.query("select i1, i2 from u");
      expect(results, [expectedRow1, expectedRow2]);
    });

    test("Call query multiple times, mixing in unnammed queries, succeeds", () async {
      await connection.query("INSERT INTO u (i1, i2) VALUES (@i1, @i2) returning i1, i2", substitutionValues: {
        "i1" : 1,
        "i2" : 2,
      });

      await connection.query("INSERT INTO n (i1, i2) VALUES (@i1, @i2) returning i1, i2", substitutionValues: {
        "i1" : 1,
        "i2" : 2,
      }, allowReuse: false);

      var results = await connection.query("INSERT INTO u (i1, i2) VALUES (@i1, @i2) returning i1, i2", substitutionValues: {
        "i1" : 2,
        "i2" : 3,
      });
      expect(results, [[2, 3]]);

      await connection.query("INSERT INTO n (i1, i2) VALUES (@i1, @i2) returning i1, i2", substitutionValues: {
        "i1" : 1,
        "i2" : 2,
      }, allowReuse: false);

      results = await connection.query("INSERT INTO u (i1, i2) VALUES (@i1, @i2) returning i1, i2", substitutionValues: {
        "i1" : 4,
        "i2" : 5,
      });
      expect(results, [[4, 5]]);
    });

    test("Call query multiple times, mixing in other named queries and unnamed queries, succeeds", () async {

    });

    test("Call a bunch of named and unnamed queries without awaiting, still process correcty", () async {

    });
  });

  group("Failure cases", () {
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

    test("A failed parse does not generate cached query", () async {

    });

    test("A failed describe does not generate cached query", () async {

    });

    test("A failed bind will return normal failure, leave cached query intact", () async {

    });

    test("Cached query that works the first time, bad params the next time, remains viable", () async {

    });
  });
}