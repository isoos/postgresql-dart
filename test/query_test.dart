import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  usePostgresDocker();
  group('Successful queries', () {
    late PostgreSQLConnection connection;

    setUp(() async {
      connection = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');
      await connection.open();
      await connection.execute('CREATE TEMPORARY TABLE t '
          '(i int, s serial, bi bigint, '
          'bs bigserial, bl boolean, si smallint, '
          't text, f real, d double precision, '
          'dt date, ts timestamp, tsz timestamptz, j jsonb, u uuid, '
          'v varchar, p point, jj json, ia _int4, ta _text, da _float8, ja _jsonb, va _varchar(20), '
          'ba _bool'
          ')');
      await connection.execute(
          'CREATE TEMPORARY TABLE u (i1 int not null, i2 int not null);');
      await connection
          .execute('CREATE TEMPORARY TABLE n (i1 int, i2 int not null);');
    });

    tearDown(() async {
      await connection.close();
    });

    test('UTF16 strings in value', () async {
      var result = await connection.query(
          'INSERT INTO t (t) values '
          "(${PostgreSQLFormat.id("t", type: PostgreSQLDataType.text)})"
          'returning t',
          substitutionValues: {
            't': '°∆',
          });

      final expectedRow = ['°∆'];
      expect(result, [expectedRow]);

      result = await connection.query('select t from t');
      expect(result.columnDescriptions, hasLength(1));
      expect(result.columnDescriptions.single.tableName, 't');
      expect(result.columnDescriptions.single.columnName, 't');
      expect(result, [expectedRow]);
    });

    test('UTF16 strings in query', () async {
      var result =
          await connection.query("INSERT INTO t (t) values ('°∆') RETURNING t");

      final expectedRow = ['°∆'];
      expect(result, [expectedRow]);

      result = await connection.query('select t from t');
      expect(result, [expectedRow]);
    });

    test('UTF16 strings in value with escape characters', () async {
      await connection.execute(
          'INSERT INTO t (t) values '
          '(${PostgreSQLFormat.id('t', type: PostgreSQLDataType.text)})',
          substitutionValues: {
            't': "'©™®'",
          });

      final expectedRow = ["'©™®'"];

      final result = await connection.query('select t from t');
      expect(result, [expectedRow]);
    });

    test('UTF16 strings in value with backslash', () async {
      await connection.execute(
          'INSERT INTO t (t) values '
          '(${PostgreSQLFormat.id('t', type: PostgreSQLDataType.text)})',
          substitutionValues: {
            't': "°\\'©™®'",
          });

      final expectedRow = ["°\\'©™®'"];

      final result = await connection.query('select t from t');
      expect(result, [expectedRow]);
    });

    test('UTF16 strings in query with escape characters', () async {
      await connection.execute("INSERT INTO t (t) values ('°''©™®''')");

      final expectedRow = ["°'©™®'"];

      final result = await connection.query('select t from t');
      expect(result, [expectedRow]);
    });

    test('Really long raw substitution value', () async {
      final result = await connection.query(
          "INSERT INTO t (t) VALUES (${PostgreSQLFormat.id("t", type: PostgreSQLDataType.text)}) returning t;",
          substitutionValues: {'t': lorumIpsum});
      expect(result, [
        [lorumIpsum]
      ]);
    });

    test('Really long SQL string in execute', () async {
      final result = await connection
          .execute("INSERT INTO t (t) VALUES ('$lorumIpsum') returning t;");
      expect(result, 1);
    });

    test('Query without specifying types', () async {
      var result = await connection.query(
          'INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz, j, u, v, p, jj, ia, ta, da, ja, va, ba) values '
          '(${PostgreSQLFormat.id('i')},'
          '${PostgreSQLFormat.id('bi')},'
          '${PostgreSQLFormat.id('bl')},'
          '${PostgreSQLFormat.id('si')},'
          '${PostgreSQLFormat.id('t')},'
          '${PostgreSQLFormat.id('f')},'
          '${PostgreSQLFormat.id('d')},'
          '${PostgreSQLFormat.id('dt')},'
          '${PostgreSQLFormat.id('ts')},'
          '${PostgreSQLFormat.id('tsz')},'
          '${PostgreSQLFormat.id('j')},'
          '${PostgreSQLFormat.id('u')},'
          '${PostgreSQLFormat.id('v')},'
          '${PostgreSQLFormat.id('p')},'
          '${PostgreSQLFormat.id('jj')},'
          '${PostgreSQLFormat.id('ia')},'
          '${PostgreSQLFormat.id('ta')},'
          '${PostgreSQLFormat.id('da')},'
          '${PostgreSQLFormat.id('ja')},'
          '${PostgreSQLFormat.id('va')},'
          '${PostgreSQLFormat.id('ba')}'
          ') returning i,s, bi, bs, bl, si, t, f, d, dt, ts, tsz, j, u, v, p, jj, ia, ta, da, ja, va, ba',
          substitutionValues: {
            'i': 1,
            'bi': 2,
            'bl': true,
            'si': 3,
            't': 'foobar',
            'f': 5.0,
            'd': 6.0,
            'dt': DateTime.utc(2000),
            'ts': DateTime.utc(2000, 2),
            'tsz': DateTime.utc(2000, 3),
            'j': {'a': 'b'},
            'u': '01234567-89ab-cdef-0123-0123456789ab',
            'v': 'abcdef',
            'p': PgPoint(1.0, 0.1),
            'jj': {'k': 'v'},
            'ia': [1, 2, 3],
            'ta': ['a', 'b"\'\\"'],
            'da': [0.1, 2.3, 1],
            'ja': [
              1,
              'a"\'\\"',
              {'k': 'v"\'\\"'}
            ],
            'va': ['a', 'b', 'c', 'd', 'e', 'f'],
            'ba': [false, true, false],
          });

      final expectedRow = [
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
        DateTime.utc(2000, 3),
        {'a': 'b'},
        '01234567-89ab-cdef-0123-0123456789ab',
        'abcdef',
        PgPoint(1.0, 0.1),
        {'k': 'v'},
        [1, 2, 3],
        ['a', 'b"\'\\"'],
        [0.1, 2.3, 1],
        [
          1,
          'a"\'\\"',
          {'k': 'v"\'\\"'}
        ],
        ['a', 'b', 'c', 'd', 'e', 'f'],
        [false, true, false]
      ];
      expect(result.columnDescriptions, hasLength(23));
      expect(result.columnDescriptions.first.tableName, 't');
      expect(result.columnDescriptions.first.columnName, 'i');
      expect(result.columnDescriptions.last.tableName, 't');
      expect(result.columnDescriptions.last.columnName, 'ba');
      expect(result, [expectedRow]);
      result = await connection.query(
          'select i,s, bi, bs, bl, si, t, f, d, dt, ts, tsz, j, u, v, p, jj, ia, ta, da, ja, va, ba from t');
      expect(result, [expectedRow]);
    });

    test('Query by specifying all types', () async {
      var result = await connection.query(
          'INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz, j, u, v, p, jj, ia, ta, da, ja, va, ba) values '
          '(${PostgreSQLFormat.id('i', type: PostgreSQLDataType.integer)},'
          '${PostgreSQLFormat.id('bi', type: PostgreSQLDataType.bigInteger)},'
          '${PostgreSQLFormat.id('bl', type: PostgreSQLDataType.boolean)},'
          '${PostgreSQLFormat.id('si', type: PostgreSQLDataType.smallInteger)},'
          '${PostgreSQLFormat.id('t', type: PostgreSQLDataType.text)},'
          '${PostgreSQLFormat.id('f', type: PostgreSQLDataType.real)},'
          '${PostgreSQLFormat.id('d', type: PostgreSQLDataType.double)},'
          '${PostgreSQLFormat.id('dt', type: PostgreSQLDataType.date)},'
          '${PostgreSQLFormat.id('ts', type: PostgreSQLDataType.timestampWithoutTimezone)},'
          '${PostgreSQLFormat.id('tsz', type: PostgreSQLDataType.timestampWithTimezone)},'
          '${PostgreSQLFormat.id('j', type: PostgreSQLDataType.jsonb)},'
          '${PostgreSQLFormat.id('u', type: PostgreSQLDataType.uuid)},'
          '${PostgreSQLFormat.id('v', type: PostgreSQLDataType.varChar)},'
          '${PostgreSQLFormat.id('p', type: PostgreSQLDataType.point)},'
          '${PostgreSQLFormat.id('jj', type: PostgreSQLDataType.json)},'
          '${PostgreSQLFormat.id('ia', type: PostgreSQLDataType.integerArray)},'
          '${PostgreSQLFormat.id('ta', type: PostgreSQLDataType.textArray)},'
          '${PostgreSQLFormat.id('da', type: PostgreSQLDataType.doubleArray)},'
          '${PostgreSQLFormat.id('ja', type: PostgreSQLDataType.jsonbArray)},'
          '${PostgreSQLFormat.id('va', type: PostgreSQLDataType.varCharArray)},'
          '${PostgreSQLFormat.id('ba', type: PostgreSQLDataType.booleanArray)}'
          ') returning i,s, bi, bs, bl, si, t, f, d, dt, ts, tsz, j, u, v, p, jj, ia, ta, da, ja, va, ba',
          substitutionValues: {
            'i': 1,
            'bi': 2,
            'bl': true,
            'si': 3,
            't': 'foobar',
            'f': 5.0,
            'd': 6.0,
            'dt': DateTime.utc(2000),
            'ts': DateTime.utc(2000, 2),
            'tsz': DateTime.utc(2000, 3),
            'j': {'key': 'value'},
            'u': '01234567-89ab-cdef-0123-0123456789ab',
            'v': 'abcdef',
            'p': PgPoint(1.0, 0.1),
            'jj': {'k': 'v'},
            'ia': [1, 2, 3],
            'ta': ['a', 'b'],
            'da': [0.1, 2.3, 1.0],
            'ja': [
              1,
              'a',
              {'k': 'v'}
            ],
            'va': ['a', 'b', 'c', 'd', 'e', 'f'],
            'ba': [false, true, true, false],
          });

      final expectedRow = [
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
        DateTime.utc(2000, 3),
        {'key': 'value'},
        '01234567-89ab-cdef-0123-0123456789ab',
        'abcdef',
        PgPoint(1.0, 0.1),
        {'k': 'v'},
        [1, 2, 3],
        ['a', 'b'],
        [0.1, 2.3, 1],
        [
          1,
          'a',
          {'k': 'v'}
        ],
        ['a', 'b', 'c', 'd', 'e', 'f'],
        [false, true, true, false],
      ];
      expect(result, [expectedRow]);

      result = await connection.query(
          'select i,s, bi, bs, bl, si, t, f, d, dt, ts, tsz, j, u, v, p, jj, ia, ta, da, ja, va, ba from t');
      expect(result, [expectedRow]);
    });

    test('Query by specifying some types', () async {
      var result = await connection.query(
          'INSERT INTO t (i, bi, bl, si, t, f, d, dt, ts, tsz) values '
          '(${PostgreSQLFormat.id('i')},'
          '${PostgreSQLFormat.id('bi', type: PostgreSQLDataType.bigInteger)},'
          '${PostgreSQLFormat.id('bl')},'
          '${PostgreSQLFormat.id('si', type: PostgreSQLDataType.smallInteger)},'
          '${PostgreSQLFormat.id('t')},'
          '${PostgreSQLFormat.id('f', type: PostgreSQLDataType.real)},'
          '${PostgreSQLFormat.id('d')},'
          '${PostgreSQLFormat.id('dt', type: PostgreSQLDataType.date)},'
          '${PostgreSQLFormat.id('ts')},'
          '${PostgreSQLFormat.id('tsz', type: PostgreSQLDataType.timestampWithTimezone)}) returning i,s, bi, bs, bl, si, t, f, d, dt, ts, tsz',
          substitutionValues: {
            'i': 1,
            'bi': 2,
            'bl': true,
            'si': 3,
            't': 'foobar',
            'f': 5.0,
            'd': 6.0,
            'dt': DateTime.utc(2000),
            'ts': DateTime.utc(2000, 2),
            'tsz': DateTime.utc(2000, 3),
          });

      final expectedRow = [
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
      expect(result, [expectedRow]);
      result = await connection
          .query('select i,s, bi, bs, bl, si, t, f, d, dt, ts, tsz from t');
      expect(result, [expectedRow]);
    });

    test('Can supply null for values (binary)', () async {
      final results = await connection.query(
          'INSERT INTO n (i1, i2) values (@i1:int4, @i2:int4) returning i1, i2',
          substitutionValues: {
            'i1': null,
            'i2': 1,
          });

      expect(results, [
        [null, 1]
      ]);
    });

    test('Can supply null for values (text)', () async {
      final results = await connection.query(
          'INSERT INTO n (i1, i2) values (@i1, @i2:int4) returning i1, i2',
          substitutionValues: {
            'i1': null,
            'i2': 1,
          });

      expect(results, [
        [null, 1]
      ]);
    });

    test('Overspecifying parameters does not impact query (text)', () async {
      final results = await connection.query(
          'INSERT INTO u (i1, i2) values (@i1, @i2) returning i1, i2',
          substitutionValues: {
            'i1': 0,
            'i2': 1,
            'i3': 0,
          });

      expect(results, [
        [0, 1]
      ]);
    });

    test('Overspecifying parameters does not impact query (binary)', () async {
      final results = await connection.query(
          'INSERT INTO u (i1, i2) values (@i1:int4, @i2:int4) returning i1, i2',
          substitutionValues: {
            'i1': 0,
            'i2': 1,
            'i3': 0,
          });

      expect(results, [
        [0, 1]
      ]);
    });

    test('Can cast text to int on db server', () async {
      final results = await connection.query(
          'INSERT INTO u (i1, i2) VALUES (@i1::int4, @i2::int4) RETURNING i1, i2',
          substitutionValues: {'i1': '0', 'i2': '1'});

      expect(results, [
        [0, 1]
      ]);
    });
  });

  group('Unsuccesful queries', () {
    late PostgreSQLConnection connection;

    setUp(() async {
      connection = PostgreSQLConnection('localhost', 5432, 'dart_test',
          username: 'dart', password: 'dart');
      await connection.open();
      await connection.execute(
          'CREATE TEMPORARY TABLE t (i1 int not null, i2 int not null)');
    });

    tearDown(() async {
      await connection.close();
    });

    test(
        'A query that fails on the server will report back an exception through the query method',
        () async {
      try {
        await connection.query('INSERT INTO t (i1) values (@i1)',
            substitutionValues: {'i1': 0});
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.severity, PostgreSQLSeverity.error);
        expect(e.message, contains('null value in column "i2"'));
      }
    });

    test(
        'Missing substitution value does not throw, query is sent to the server without changing that part.',
        () async {
      final rs1 = await connection
          .query('SELECT *  FROM (VALUES (\'user@domain.com\')) t1 (col1)');
      expect(rs1.first.toColumnMap(), {'col1': 'user@domain.com'});

      final rs2 = await connection.query(
        'SELECT *  FROM (VALUES (\'user@domain.com\')) t1 (col1) WHERE col1 > @u1',
        substitutionValues: {'u1': 'hello@domain.com'},
      );
      expect(rs2.first.toColumnMap(), {'col1': 'user@domain.com'});
    });

    test('Wrong type for parameter in substitution values fails', () async {
      try {
        await connection.query(
            'INSERT INTO t (i1, i2) values (@i1:int4, @i2:int4)',
            substitutionValues: {'i1': '1', 'i2': 1});
        expect(true, false);
      } on FormatException catch (e) {
        expect(e.toString(), contains('Invalid type for parameter value'));
      }
    });

    test('Invalid type code', () async {
      try {
        await connection.query(
            'INSERT INTO t (i1, i2) values (@i1:qwerty, @i2:int4)',
            substitutionValues: {'i1': '1', 'i2': 1});
        expect(true, false);
      } on FormatException catch (e) {
        expect(e.toString(), contains('Invalid type code'));
        expect(e.toString(), contains("'@i1:qwerty"));
      }
    });
  });
}

const String lorumIpsum = '''Lorem
        ipsum dolor sit amet, consectetur adipiscing elit. Quisque in accumsan
        felis. Nunc semper velit purus, a pellentesque mauris aliquam ut. Sed
        laoreet iaculis nunc sit amet dignissim. Aenean venenatis sollicitudin
        justo, quis imperdiet diam fringilla quis. Fusce nec mauris imperdiet
        dui iaculis consequat. Integer convallis justo a neque finibus imperdiet
        et nec sem. In laoreet quis ante eget pellentesque. Nunc posuere faucibus
        nibh eu aliquet. Aliquam rutrum posuere nisi, ut maximus mauris tincidunt
        at. Integer fermentum venenatis viverra. Vivamus non magna malesuada,
        ullamcorper neque ut, auctor justo. Donec ut mattis elit, eget varius urna.
        Vestibulum consectetur aliquet semper. Nullam pellentesque nunc quis risus
        rutrum viverra. Fusce porta tortor in neque maximus efficitur. Aenean
        euismod sollicitudin neque a tristique. Donec consequat egestas vulputate.
        Pellentesque ultricies pellentesque ex pellentesque gravida. Praesent
        lacinia tortor vitae dolor vehicula iaculis. In sed egestas lacus, eget
        semper mauris. Sed augue augue, vehicula eu ornare quis, egestas id libero.
        Sed quis enim lobortis, sollicitudin nibh eu, maximus justo. Nam mauris
        tortor, suscipit dapibus sodales non, suscipit eu felis. Nam pellentesque
        eleifend risus rhoncus facilisis. Vestibulum commodo fringilla enim tempus
        hendrerit. Quisque a est varius, efficitur magna ac, condimentum metus.
        In quam nisi, facilisis at pulvinar vitae, placerat quis est. Duis sagittis
        non leo id placerat. Integer lobortis tellus rhoncus mi gravida, vel posuere
        eros convallis. Suspendisse finibus elit viverra purus dictum, eget ultrices
        risus hendrerit. Sed fermentum elit eu nibh pellentesque, eget suscipit
        purus malesuada. Duis quis convallis quam, vel rutrum metus. Sed pulvinar
        nisi non mauris laoreet, a faucibus turpis euismod. Cras et arcu hendrerit,
        commodo elit eget, gravida lectus. Nulla euismod erat id venenatis sodales.
        Duis non dolor facilisis, egestas felis pellentesque, porttitor augue.
        Vestibulum eu tincidunt sapien, volutpat lobortis mi. Cum sociis natoque
        penatibus et magnis dis parturient montes, nascetur ridiculus mus.
        Praesent nec rhoncus erat, molestie imperdiet magna. Quisque vel eleifend
        lectus. Cras ut orci et sem pellentesque pharetra. Donec ac urna sit amet
        est viverra placerat. Duis sit amet ipsum venenatis, aliquam mauris quis,
        fringilla leo. Suspendisse potenti. Cum sociis natoque penatibus et magnis
        dis parturient montes, nascetur ridiculus mus. Sed eu condimentum nisi,
        lobortis mollis est. Nam auctor auctor enim sit amet tincidunt. Proin
        hendrerit volutpat vestibulum. Fusce facilisis rutrum pretium. Proin eget
        imperdiet elit. Phasellus vulputate ex malesuada porttitor lobortis.
        Curabitur vitae orci et lacus condimentum varius fringilla blandit metus.
        Class aptent taciti sociosqu ad litora torquent per conubia nostra, per
        inceptos himenaeos. Suspendisse vehicula mauris in libero finibus bibendum.
        Phasellus ligula odio, pharetra vel metus maximus, efficitur pretium erat.
        Morbi mi purus, sagittis quis congue et, pharetra id mauris. Cras eget neque
        id erat cursus pellentesque et sed ipsum. In vel nibh at nulla pellentesque
        elementum. Cras ultricies molestie massa, nec consequat urna scelerisque eu.
        Etiam varius fermentum mi non tincidunt. Pellentesque vel elit id turpis
        lobortis ullamcorper et a lorem. Nunc purus nulla, feugiat vitae congue
        imperdiet, auctor sit amet ante. Nulla facilisi. Donec luctus sem vel diam
        fringilla, vel fermentum augue placerat. Suspendisse et eros dignissim ipsum
        vestibulum elementum. Curabitur scelerisque tortor sit amet libero pharetra
        condimentum. Maecenas molestie non erat sed blandit. Ut lectus est, consequat
        a auctor in, vulputate ac mi. Sed sem tortor, consectetur eget tincidunt et,
        iaculis non diam. Praesent quis ipsum sem. Nulla lobortis nec ex non facilisis.
        Aliquam porttitor metus eu velit convallis volutpat. Duis nec euismod urna.
        Nullam molestie ligula urna, non laoreet mi facilisis quis. Donec aliquam
        eget diam sit amet facilisis. Sed suscipit, justo non congue fringilla,
        augue tellus volutpat velit, a dignissim felis quam sit amet metus.
        Interdum et malesuada fames ac ante ipsum primis in faucibus. Duis
        malesuada cursus dolor, eget aliquam leo ultricies at. Fusce fringilla
        sed quam id finibus. Suspendisse ullamcorper, urna non feugiat elementum,
        neque tortor suscipit elit, id condimentum lacus augue ut massa. Lorem
        ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit
        amet, consectetur adipiscing elit. Mauris tempor faucibus ipsum, vitae
        blandit libero sollicitudin nec. Cras elementum mauris id ipsum tempus
        ullamcorper. Class aptent taciti sociosqu ad litora torquent per conubia
        nostra, per inceptos himenaeos. Donec vehicula, sapien sit amet pulvinar
        pretium, elit mauris finibus nunc, ac pellentesque justo dolor eu dui.
        Nulla tincidunt porttitor semper. Maecenas nunc enim, feugiat vel ex a,
        pulvinar lacinia dolor. Donec in tortor ac justo porta malesuada et nec
        ante. Maecenas vel bibendum nunc. Ut sollicitudin elementum orci ac auctor.
        Duis blandit quam quis dapibus rhoncus. Proin sagittis feugiat mi ac
        consequat. Sed maximus sodales diam id luctus. In cursus dictum rutrum.
        Vestibulum vitae enim odio. Morbi non pharetra sem, at molestie lorem.
        Nam libero est, imperdiet at aliquam vitae, mollis eget erat. Vivamus
        eu nisi auctor, pharetra ligula nec, rhoncus augue. Quisque viverra
        mollis velit, nec euismod lectus sagittis eget. Curabitur sed augue
        vestibulum, luctus dolor nec, ornare ligula. Fusce lectus nunc,
        tincidunt ut felis sed, placerat molestie risus. Etiam vel libero tellus.
        Quisque elementum turpis non tempus dignissim. Pellentesque consectetur
        tellus et urna ultrices elementum. Proin feugiat mi eu cursus mattis.
        Proin tincidunt tincidunt turpis, in vulputate mauris. Cras posuere
        lorem in erat lobortis sollicitudin. Proin in pulvinar diam, in convallis
        urna. Praesent eget quam non velit dapibus tempus. Maecenas molestie nec
        magna id auctor. Integer in sem non arcu dapibus iaculis. Sed eget massa
        est. Cras dictum erat vel rutrum suscipit. In vehicula lorem non tempus
        dignissim. Praesent gravida condimentum sem id elementum. Duis laoreet,
        diam quis imperdiet mollis, nulla erat dapibus nisl, ac varius ex quam
        id purus. Donec dignissim nulla lacinia eros venenatis tempor. Proin purus
        lacus, ultrices non sodales quis, commodo et metus. Duis ante massa,
        faucibus nec pharetra ut, ultricies et turpis. Morbi volutpat hendrerit
        lacus, ut vehicula nibh tempor eget. Cras quis iaculis nisi, sit amet
        placerat orci. Nam scelerisque velit malesuada, iaculis urna et, condimentum
        dui. Nulla convallis augue vitae consequat laoreet. Quisque fermentum
        ullamcorper magna, ut aliquam nunc facilisis in. Praesent tempus ullamcorper
        massa, et fermentum purus bibendum quis. Sed sed venenatis odio, eget
        euismod nisl. Nam et imperdiet dolor. Nam convallis justo a diam ultrices
        gravida quis vel sapien. Vivamus aliquet lobortis augue ut accumsan. Donec
        mi dolor, bibendum in mattis nec, porta vitae tellus. Donec eu tincidunt
        lectus. Fusce placerat euismod turpis, et porta ligula tincidunt non.
        Cras ac vestibulum diam. Cras eu quam finibus, feugiat libero vel, ornare
        purus. Duis consectetur dictum metus non cursus. Vestibulum semper id erat
        eget bibendum. Etiam vitae dui quis justo pretium pellentesque. Aenean sed
        tellus eu odio volutpat consectetur condimentum vel leo. Etiam vulputate
        risus tellus, at viverra enim vulputate vel. Mauris eu tortor nulla.
        Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere
        cubilia Curae; Nam ac nulla in ex lobortis tincidunt at non urna. Donec
        congue lectus ut mauris eleifend cursus. Interdum et malesuada fames ac ante
        ipsum primis in faucibus. Mauris sit amet porta mi, non mollis dui. Nullam
        cursus sapien at pretium porta. Donec ac mauris pharetra, vehicula dolor
        nec, lacinia mauris. Aliquam et felis finibus, cursus neque a, viverra sem.
        Pellentesque habitant morbi tristique senectus et netus et malesuada fames
        ac turpis egestas. Proin malesuada orci sit amet neque dapibus bibendum.
        In lobortis imperdiet condimentum. Nullam est nisi, efficitur ac consectetur
        eu, efficitur a libero. In nullam.''';
