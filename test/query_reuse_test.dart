import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'dart:async';

String sid(String id, PostgreSQLDataType dt) => PostgreSQLFormat.id(id, type: dt);

void main() {
  group("Retaining type information", () {
    PostgreSQLConnection connection;

    setUp(() async {
      connection = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");
      await connection.open();
      await connection.execute("CREATE TEMPORARY TABLE t (i int, s serial, bi bigint, bs bigserial, bl boolean, si smallint, t text, f real, d double precision, dt date, ts timestamp, tsz timestamptz)");
    });

    tearDown(() async {
      await connection.close();
    });

    test("Call query multiple times with all parameter types succeeds", () async {
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

    test("Call query multiple times without type data succeeds ", () async {
      var insertQueryString = "INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz) VALUES "
          "(@i, @bi, @bl, @si, @t, @f, @d, @dt, @ts, @tsz) "
          "returning i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz";
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
    });

    test("Call query multiple times with partial parameter type info succeeds", () async {
      var insertQueryString = "INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz) VALUES "
          "(${sid("i", PostgreSQLDataType.integer)}, @bi,"
          "${sid("bl", PostgreSQLDataType.boolean)}, @si,"
          "${sid("t", PostgreSQLDataType.text)}, @f,"
          "${sid("d", PostgreSQLDataType.double)}, @dt,"
          "${sid("ts", PostgreSQLDataType.timestampWithoutTimezone)}, @tsz"
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
  });

  group("Mixing prepared statements", () {
    PostgreSQLConnection connection;

    setUp(() async {
      connection = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");
      await connection.open();
      await connection.execute("CREATE TEMPORARY TABLE t (i1 int not null, i2 int not null)");
      await connection.execute("INSERT INTO t (i1, i2) VALUES (0, 1)");
      await connection.execute("INSERT INTO t (i1, i2) VALUES (1, 2)");
      await connection.execute("INSERT INTO t (i1, i2) VALUES (2, 3)");
      await connection.execute("INSERT INTO t (i1, i2) VALUES (3, 4)");
    });

    tearDown(() async {
      await connection.close();
    });

    test("Call query multiple times, mixing in unnammed queries, succeeds", () async {
      var results = await connection.query("select i1, i2 from t where i1 > @i1", substitutionValues: {
        "i1" : 1
      });
      expect(results, [[2, 3], [3, 4]]);

      results = await connection.query("select i1,i2 from t where i1 > @i1", substitutionValues: {
        "i1" : 1
      }, allowReuse: false);
      expect(results, [[2, 3], [3, 4]]);

      results = await connection.query("select i1, i2 from t where i1 > @i1", substitutionValues: {
        "i1" : 2
      });
      expect(results, [[3, 4]]);

      results = await connection.query("select i1,i2 from t where i1 > @i1", substitutionValues: {
        "i1" : 0
      }, allowReuse: false);
      expect(results, [[1, 2], [2, 3], [3, 4]]);

      results = await connection.query("select i1, i2 from t where i1 > @i1", substitutionValues: {
        "i1" : 2
      });
      expect(results, [[3, 4]]);
    });

    test("Call query multiple times, mixing in other named queries, succeeds", () async {
      var results = await connection.query("select i1, i2 from t where i1 > @i1", substitutionValues: {
        "i1" : 1
      });
      expect(results, [[2, 3], [3, 4]]);

      results = await connection.query("select i1,i2 from t where i2 < @i2", substitutionValues: {
        "i2" : 1
      });
      expect(results, []);

      results = await connection.query("select i1, i2 from t where i1 > @i1", substitutionValues: {
        "i1" : 2
      });
      expect(results, [[3, 4]]);

      results = await connection.query("select i1,i2 from t where i2 < @i2", substitutionValues: {
        "i2" : 2
      });
      expect(results, [[0, 1]]);

      results = await connection.query("select i1, i2 from t where i1 > @i1", substitutionValues: {
        "i1" : 2
      });
      expect(results, [[3, 4]]);
    });

    test("Call a bunch of named and unnamed queries without awaiting, still process correctly", () async {
      var futures = [
        connection.query("select i1, i2 from t where i1 > @i1", substitutionValues: {
          "i1" : 1
        }),
        connection.execute("select 1"),
        connection.query("select i1,i2 from t where i2 < @i2", substitutionValues: {
          "i2" : 1
        }),
        connection.query("select i1, i2 from t where i1 > @i1", substitutionValues: {
          "i1" : 2
        }),
        connection.query("select 1", allowReuse: false),
        connection.query("select i1,i2 from t where i2 < @i2", substitutionValues: {
          "i2" : 2
        }),
        connection.query("select i1, i2 from t where i1 > @i1", substitutionValues: {
          "i1" : 2
        })
      ];

      var results = await Future.wait(futures);
      expect(results, [[[2, 3], [3, 4]], 1, [], [[3, 4]], [[1]], [[0, 1]], [[3, 4]]]);
    });

    test("Make a prepared query that has no parameters", () async {
      var results = await connection.query("select 1");
      expect(results, [[1]]);

      results = await connection.query("select 1");
      expect(results, [[1]]);
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