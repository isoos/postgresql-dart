import 'dart:async';
import 'dart:mirrors';

import 'package:postgres/postgres.dart';
import 'package:postgres/src/query_cache.dart';
import 'package:test/test.dart';

import 'docker.dart';

String sid(String id, PostgreSQLDataType dt) =>
    PostgreSQLFormat.id(id, type: dt);

void main() {
  usePostgresDocker();
  group('Retaining type information', () {
    late PostgreSQLConnection connection;

    setUp(() async {
      connection = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');
      await connection.open();
      await connection.execute(
          'CREATE TEMPORARY TABLE t (i int, s serial, bi bigint, bs bigserial, bl boolean, si smallint, t text, f real, d double precision, dt date, ts timestamp, tsz timestamptz)');
    });

    tearDown(() async {
      await connection.close();
    });

    test('Call query multiple times with all parameter types succeeds',
        () async {
      final insertQueryString =
          'INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz) VALUES '
          '(${sid('i', PostgreSQLDataType.integer)}, ${sid('bi', PostgreSQLDataType.bigInteger)},'
          '${sid('bl', PostgreSQLDataType.boolean)}, ${sid('si', PostgreSQLDataType.smallInteger)},'
          '${sid('t', PostgreSQLDataType.text)}, ${sid('f', PostgreSQLDataType.real)},'
          '${sid('d', PostgreSQLDataType.double)}, ${sid('dt', PostgreSQLDataType.date)},'
          '${sid('ts', PostgreSQLDataType.timestampWithoutTimezone)}, ${sid('tsz', PostgreSQLDataType.timestampWithTimezone)}'
          ') returning i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz';
      var results =
          await connection.query(insertQueryString, substitutionValues: {
        'i': 1,
        'bi': 2,
        'bl': true,
        'si': 3,
        't': 'foobar',
        'f': 5.0,
        'd': 6.0,
        'dt': DateTime.utc(2000),
        'ts': DateTime.utc(2000, 2),
        'tsz': DateTime.utc(2000, 3)
      });

      expect(hasCachedQueryNamed(connection, insertQueryString), true);

      final expectedRow1 = [
        1,
        1,
        2,
        1,
        true,
        3,
        'foobar',
        5.0,
        6.0,
        DateTime.utc(2000),
        DateTime.utc(2000, 2),
        DateTime.utc(2000, 3)
      ];
      expect(results, [expectedRow1]);

      results = await connection.query(insertQueryString, substitutionValues: {
        'i': 2,
        'bi': 3,
        'bl': false,
        'si': 4,
        't': 'barfoo',
        'f': 6.0,
        'd': 7.0,
        'dt': DateTime.utc(2001),
        'ts': DateTime.utc(2001, 2),
        'tsz': DateTime.utc(2001, 3)
      });

      expect(hasCachedQueryNamed(connection, insertQueryString), true);

      final expectedRow2 = [
        2,
        2,
        3,
        2,
        false,
        4,
        'barfoo',
        6.0,
        7.0,
        DateTime.utc(2001),
        DateTime.utc(2001, 2),
        DateTime.utc(2001, 3)
      ];
      expect(results, [expectedRow2]);

      results = await connection
          .query('select i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t');
      expect(results, [expectedRow1, expectedRow2]);

      expect(
          hasCachedQueryNamed(connection,
              'select i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t'),
          true);

      results = await connection.query(
          'select i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t where i < @i',
          substitutionValues: {'i': 0});
      expect(results, []);

      results = await connection.query(
          'select i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t where i < @i',
          substitutionValues: {'i': 2});
      expect(results, [expectedRow1]);

      results = await connection.query(
          'select i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t where i < @i',
          substitutionValues: {'i': 5});
      expect(results, [expectedRow1, expectedRow2]);

      expect(hasCachedQueryNamed(connection, insertQueryString), true);
    });

    test('Call query multiple times without type data succeeds ', () async {
      final insertQueryString =
          'INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz) VALUES '
          '(@i, @bi, @bl, @si, @t, @f, @d, @dt, @ts, @tsz) '
          'returning i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz';
      var results =
          await connection.query(insertQueryString, substitutionValues: {
        'i': 1,
        'bi': 2,
        'bl': true,
        'si': 3,
        't': 'foobar',
        'f': 5.0,
        'd': 6.0,
        'dt': DateTime.utc(2000),
        'ts': DateTime.utc(2000, 2),
        'tsz': DateTime.utc(2000, 3)
      });

      final expectedRow1 = [
        1,
        1,
        2,
        1,
        true,
        3,
        'foobar',
        5.0,
        6.0,
        DateTime.utc(2000),
        DateTime.utc(2000, 2),
        DateTime.utc(2000, 3)
      ];
      expect(results, [expectedRow1]);

      results = await connection.query(insertQueryString, substitutionValues: {
        'i': 2,
        'bi': 3,
        'bl': false,
        'si': 4,
        't': 'barfoo',
        'f': 6.0,
        'd': 7.0,
        'dt': DateTime.utc(2001),
        'ts': DateTime.utc(2001, 2),
        'tsz': DateTime.utc(2001, 3)
      });

      final expectedRow2 = [
        2,
        2,
        3,
        2,
        false,
        4,
        'barfoo',
        6.0,
        7.0,
        DateTime.utc(2001),
        DateTime.utc(2001, 2),
        DateTime.utc(2001, 3)
      ];
      expect(results, [expectedRow2]);
    });

    test('Call query multiple times with partial parameter type info succeeds',
        () async {
      final insertQueryString =
          'INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz) VALUES '
          '(${sid('i', PostgreSQLDataType.integer)}, @bi,'
          '${sid('bl', PostgreSQLDataType.boolean)}, @si,'
          '${sid('t', PostgreSQLDataType.text)}, @f,'
          '${sid('d', PostgreSQLDataType.double)}, @dt,'
          '${sid('ts', PostgreSQLDataType.timestampWithoutTimezone)}, @tsz'
          ') returning i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz';
      var results =
          await connection.query(insertQueryString, substitutionValues: {
        'i': 1,
        'bi': 2,
        'bl': true,
        'si': 3,
        't': 'foobar',
        'f': 5.0,
        'd': 6.0,
        'dt': DateTime.utc(2000),
        'ts': DateTime.utc(2000, 2),
        'tsz': DateTime.utc(2000, 3)
      });

      final expectedRow1 = [
        1,
        1,
        2,
        1,
        true,
        3,
        'foobar',
        5.0,
        6.0,
        DateTime.utc(2000),
        DateTime.utc(2000, 2),
        DateTime.utc(2000, 3)
      ];
      expect(results, [expectedRow1]);

      results = await connection.query(insertQueryString, substitutionValues: {
        'i': 2,
        'bi': 3,
        'bl': false,
        'si': 4,
        't': 'barfoo',
        'f': 6.0,
        'd': 7.0,
        'dt': DateTime.utc(2001),
        'ts': DateTime.utc(2001, 2),
        'tsz': DateTime.utc(2001, 3)
      });

      final expectedRow2 = [
        2,
        2,
        3,
        2,
        false,
        4,
        'barfoo',
        6.0,
        7.0,
        DateTime.utc(2001),
        DateTime.utc(2001, 2),
        DateTime.utc(2001, 3)
      ];
      expect(results, [expectedRow2]);

      results = await connection
          .query('select i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t');
      expect(results, [expectedRow1, expectedRow2]);

      results = await connection.query(
          'select i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t where i < @i',
          substitutionValues: {'i': 0});
      expect(results, []);

      results = await connection.query(
          'select i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t where i < @i',
          substitutionValues: {'i': 2});
      expect(results, [expectedRow1]);

      results = await connection.query(
          'select i, s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t where i < @i',
          substitutionValues: {'i': 5});
      expect(results, [expectedRow1, expectedRow2]);
    });
  });

  group('Mixing prepared statements', () {
    late PostgreSQLConnection connection;

    setUp(() async {
      connection = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');
      await connection.open();
      await connection.execute(
          'CREATE TEMPORARY TABLE t (i1 int not null, i2 int not null)');
      await connection.execute('INSERT INTO t (i1, i2) VALUES (0, 1)');
      await connection.execute('INSERT INTO t (i1, i2) VALUES (1, 2)');
      await connection.execute('INSERT INTO t (i1, i2) VALUES (2, 3)');
      await connection.execute('INSERT INTO t (i1, i2) VALUES (3, 4)');
    });

    tearDown(() async {
      await connection.close();
    });

    test('Call query multiple times, mixing in unnammed queries, succeeds',
        () async {
      var results = await connection.query(
          'select i1, i2 from t where i1 > @i1',
          substitutionValues: {'i1': 1});
      expect(results, [
        [2, 3],
        [3, 4]
      ]);

      results = await connection.query('select i1,i2 from t where i1 > @i1',
          substitutionValues: {'i1': 1}, allowReuse: false);
      expect(results, [
        [2, 3],
        [3, 4]
      ]);

      results = await connection.query('select i1, i2 from t where i1 > @i1',
          substitutionValues: {'i1': 2});
      expect(results, [
        [3, 4]
      ]);

      results = await connection.query('select i1,i2 from t where i1 > @i1',
          substitutionValues: {'i1': 0}, allowReuse: false);
      expect(results, [
        [1, 2],
        [2, 3],
        [3, 4]
      ]);

      results = await connection.query('select i1, i2 from t where i1 > @i1',
          substitutionValues: {'i1': 2});
      expect(results, [
        [3, 4]
      ]);

      expect(
          hasCachedQueryNamed(
              connection, 'select i1, i2 from t where i1 > @i1'),
          true);
      expect(getQueryCache(connection).length, 1);
    });

    test('Call query multiple times, mixing in other named queries, succeeds',
        () async {
      var results = await connection.query(
          'select i1, i2 from t where i1 > @i1',
          substitutionValues: {'i1': 1});
      expect(results, [
        [2, 3],
        [3, 4]
      ]);

      results = await connection.query('select i1,i2 from t where i2 < @i2',
          substitutionValues: {'i2': 1});
      expect(results, []);

      results = await connection.query('select i1, i2 from t where i1 > @i1',
          substitutionValues: {'i1': 2});
      expect(results, [
        [3, 4]
      ]);

      results = await connection.query('select i1,i2 from t where i2 < @i2',
          substitutionValues: {'i2': 2});
      expect(results, [
        [0, 1]
      ]);

      results = await connection.query('select i1, i2 from t where i1 > @i1',
          substitutionValues: {'i1': 2});
      expect(results, [
        [3, 4]
      ]);

      expect(
          hasCachedQueryNamed(
              connection, 'select i1, i2 from t where i1 > @i1'),
          true);
      expect(
          hasCachedQueryNamed(connection, 'select i1,i2 from t where i2 < @i2'),
          true);
      expect(getQueryCache(connection).length, 2);
    });

    test(
        'Call a bunch of named and unnamed queries without awaiting, still process correctly',
        () async {
      final futures = [
        connection.query('select i1, i2 from t where i1 > @i1',
            substitutionValues: {'i1': 1}),
        connection.execute('select 1'),
        connection.query('select i1,i2 from t where i2 < @i2',
            substitutionValues: {'i2': 1}),
        connection.query('select i1, i2 from t where i1 > @i1',
            substitutionValues: {'i1': 2}),
        connection.query('select 1', allowReuse: false),
        connection.query('select i1,i2 from t where i2 < @i2',
            substitutionValues: {'i2': 2}),
        connection.query('select i1, i2 from t where i1 > @i1',
            substitutionValues: {'i1': 2})
      ];

      final results = await Future.wait(futures);
      expect(results, [
        [
          [2, 3],
          [3, 4]
        ],
        1,
        [],
        [
          [3, 4]
        ],
        [
          [1]
        ],
        [
          [0, 1]
        ],
        [
          [3, 4]
        ]
      ]);
    });

    test('Make a prepared query that has no parameters', () async {
      var results = await connection.query('select 1');
      expect(results, [
        [1]
      ]);

      results = await connection.query('select 1');
      expect(results, [
        [1]
      ]);
    });
  });

  group('Failure cases', () {
    late PostgreSQLConnection connection;

    setUp(() async {
      connection = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');
      await connection.open();
      await connection.execute(
          'CREATE TEMPORARY TABLE t (i int, s serial, bi bigint, bs bigserial, bl boolean, si smallint, t text, f real, d double precision, dt date, ts timestamp, tsz timestamptz)');
      await connection.execute(
          'CREATE TEMPORARY TABLE u (i1 int not null, i2 int not null);');
      await connection
          .execute('CREATE TEMPORARY TABLE n (i1 int, i2 int not null);');
    });

    tearDown(() async {
      await connection.close();
    });

    test('A failed parse does not generate cached query', () async {
      try {
        await connection.query('ljkasd');
        expect(true, false);
      } on PostgreSQLException {
        // ignore
      }

      expect(getQueryCache(connection).isEmpty, true);
    });

    test(
        'Trying to parse/describe a query with inaccurate types fails and does not cache query',
        () async {
      final string =
          'insert into u (i1, i2) values (@i1:text, @i2:text) returning i1, i2';
      try {
        await connection
            .query(string, substitutionValues: {'i1': 'foo', 'i2': 'bar'});

        expect(true, false);
      } on PostgreSQLException {
        // ignore
      }

      expect(getQueryCache(connection).length, 0);
    });

    test(
        'A failed bind on initial query fails query, but can still make query later',
        () async {
      final string =
          'insert into u (i1, i2) values (@i1, @i2) returning i1, i2';
      try {
        await connection
            .query(string, substitutionValues: {'i1': 'foo', 'i2': 'bar'});

        expect(true, false);
      } on PostgreSQLException {
        // ignores
      }

      expect(hasCachedQueryNamed(connection, string), false);

      var results = await connection.query('select i1, i2 from u');
      expect(results, []);

      await connection.query(string, substitutionValues: {'i1': 1, 'i2': 2});
      results = await connection.query('select i1, i2 from u');
      expect(results, [
        [1, 2]
      ]);
      expect(hasCachedQueryNamed(connection, string), true);
    });

    test(
        'Cached query that works the first time, wrong type for params the next time throws early error but can still be used',
        () async {
      await connection.query(
          'insert into u (i1, i2) values (@i1:int4, @i2:int4) returning i1, i2',
          substitutionValues: {'i1': 1, 'i2': 2});
      await connection.query(
          'insert into u (i1, i2) values (@i1:int4, @i2:int4) returning i1, i2',
          substitutionValues: {'i1': 2, 'i2': 3});

      final string = 'select i1, i2 from u where i1 = @i:int4';
      var results =
          await connection.query(string, substitutionValues: {'i': 1});
      expect(results, [
        [1, 2]
      ]);
      expect(hasCachedQueryNamed(connection, string), true);

      try {
        await connection.query(string, substitutionValues: {'i': 'foo'});
      } on FormatException {
        // ignore
      }

      results = await connection.query(string, substitutionValues: {'i': 2});
      expect(results, [
        [2, 3]
      ]);
      expect(hasCachedQueryNamed(connection, string), true);
    });

    test(
        'Send two queries that will be the same prepared statement async, first one fails on bind',
        () async {
      final rs = await connection.query('SELECT 1');
      await connection.query(
          'insert into u (i1, i2) values (@i1:int4, @i2:int4) returning i1, i2',
          substitutionValues: {'i1': 1, 'i2': 2},
          allowReuse: false);

      final string = 'select i1, i2 from u where i1 = @i:int4';
      // ignore: unawaited_futures
      connection.query(string,
          substitutionValues: {'i': 'foo'}).catchError((e) => rs);

      final results =
          await connection.query(string, substitutionValues: {'i': 1});

      expect(results, [
        [1, 2]
      ]);
      expect(getQueryCache(connection).length, 2); // 1: SELECT 1
      expect(hasCachedQueryNamed(connection, string), true);
    });
  });
}

QueryCache getQueryCache(PostgreSQLConnection connection) {
  final cacheMirror = reflect(connection).type.declarations.values.firstWhere(
      (DeclarationMirror dm) => dm.simpleName.toString().contains('_cache'));
  return reflect(connection).getField(cacheMirror.simpleName).reflectee
      as QueryCache;
}

bool hasCachedQueryNamed(PostgreSQLConnection connection, String name) {
  return getQueryCache(connection)[name] != null;
}
