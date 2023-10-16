import 'package:postgres/postgres.dart';
import 'package:postgres/src/v3/query_description.dart';
import 'package:test/test.dart';

void main() {
  test('can declare variables', () {
    final desc = InternalQueryDescription.map('SELECT @x:int8, @y:boolean, @z');

    expect(desc.transformedSql, r'SELECT $1, $2, $3');
    expect(
      desc.namedVariables,
      {'x': 1, 'y': 2, 'z': 3},
    );
    expect(desc.parameterTypes, [
      PgDataType.bigInteger, // x
      PgDataType.boolean, // y
      null, // z, didn't have a specified type
    ]);

    expect(() => desc.bindParameters(null), throwsArgumentError);

    expect(
      desc.bindParameters(
          {'x': 4, 'y': true, 'z': PgTypedParameter(PgDataType.text, 'z')}),
      [
        PgTypedParameter(PgDataType.bigInteger, 4),
        PgTypedParameter(PgDataType.boolean, true),
        PgTypedParameter(PgDataType.text, 'z'),
      ],
    );
    expect(desc.bindParameters({'x': 4, 'y': true, 'z': 'z'}), [
      PgTypedParameter(PgDataType.bigInteger, 4),
      PgTypedParameter(PgDataType.boolean, true),
      PgTypedParameter(PgDataType.unspecified, 'z'),
    ]);

    // Make sure we can still bind by index
    expect(
      desc.bindParameters([1, true, PgTypedParameter(PgDataType.text, 'z')]),
      [
        PgTypedParameter(PgDataType.bigInteger, 1),
        PgTypedParameter(PgDataType.boolean, true),
        PgTypedParameter(PgDataType.text, 'z'),
      ],
    );
    expect(
      desc.bindParameters([1, true, 3]),
      [
        PgTypedParameter(PgDataType.bigInteger, 1),
        PgTypedParameter(PgDataType.boolean, true),
        PgTypedParameter(PgDataType.unspecified, 3),
      ],
    );
  });

  test('can use the same variable more than once', () {
    final desc = InternalQueryDescription.map(
        'SELECT * FROM foo WHERE a = @x OR bar = @y OR b = @x');
    expect(desc.transformedSql,
        r'SELECT * FROM foo WHERE a = $1 OR bar = $2 OR b = $1');
    expect(desc.namedVariables?.keys, ['x', 'y']);
  });

  test('can use custom variable symbol', () {
    final desc = InternalQueryDescription.map(
        'SELECT * FROM foo WHERE a = :x:int8',
        substitution: ':');
    expect(desc.transformedSql, r'SELECT * FROM foo WHERE a = $1');
    expect(desc.namedVariables?.keys, ['x']);
    expect(desc.parameterTypes, [PgDataType.bigInteger]);
  });

  test('finds correct end for string literal', () {
    final desc = InternalQueryDescription.map(r"SELECT e'@a\\' @b");
    expect(desc.transformedSql, r"SELECT e'@a\\' $1");
    expect(desc.namedVariables?.keys, ['b']);
  });

  group('VARCHAR(x)', () {
    test('accept with some length', () {
      final desc = InternalQueryDescription.map('SELECT @x:_varchar(10), 0');
      expect(desc.transformedSql, r'SELECT $1, 0');
      expect(desc.namedVariables, {'x': 1});
      expect(desc.parameterTypes, [PgDataType.varCharArray]);
    });

    test('throws', () {
      final badSnippets = [
        '@x:_varchar(',
        '@x:_varchar()',
        '@x:_varchar(())',
        '@x:_varchar((1))',
        '@x:_varchar(a)',
        '@x:_varchar( 0 )',
      ];
      for (final snippet in badSnippets) {
        expect(
          () => InternalQueryDescription.map('SELECT $snippet'),
          throwsFormatException,
          reason: snippet,
        );
        expect(
          () => InternalQueryDescription.map('SELECT $snippet, 0'),
          throwsFormatException,
          reason: '$snippet, 0',
        );
      }
    });
  });

  group('ignores', () {
    test('line comments', () {
      final desc = InternalQueryDescription.map('SELECT @1, -- @2 \n @3');
      expect(desc.transformedSql, r'SELECT $1,  $2');
      expect(desc.namedVariables?.keys, ['1', '3']);
    });

    test('block comments', () {
      final desc = InternalQueryDescription.map(
          'SELECT @1 /* this is ignored: @2 */, @3');
      expect(desc.transformedSql, r'SELECT $1 , $2');
      expect(desc.namedVariables?.keys, ['1', '3']);
    });

    test('string literals', () {
      final desc = InternalQueryDescription.map(
          "SELECT @1, 'isn''t a variable: @2', @3");
      expect(desc.transformedSql, r"SELECT $1, 'isn''t a variable: @2', $2");
      expect(desc.namedVariables?.keys, ['1', '3']);
    });

    test('string literals with C-style escapes', () {
      final desc = InternalQueryDescription.map(
          r"SELECT @1, E'isn\'t a variable: @2', @3");
      expect(desc.transformedSql, r"SELECT $1, E'isn\'t a variable: @2', $2");
      expect(desc.namedVariables?.keys, ['1', '3']);
    });

    test('strings with unicode escapes', () {
      final desc = InternalQueryDescription.map(r"U&'d\0061t@1\+000061', @2");
      expect(desc.transformedSql, r"U&'d\0061t@1\+000061', $1");
      expect(desc.namedVariables?.keys, ['2']);
    });

    test('identifiers', () {
      final desc = InternalQueryDescription.map('SELECT @1 AS "@2", @3');
      expect(desc.transformedSql, r'SELECT $1 AS "@2", $2');
      expect(desc.namedVariables?.keys, ['1', '3']);
    });

    test('identifiers with unicode escapes', () {
      final desc =
          InternalQueryDescription.map(r'SELECT U&"d\0061t@1\+000061", @2');
      expect(desc.transformedSql, r'SELECT U&"d\0061t@1\+000061", $1');
      expect(desc.namedVariables?.keys, ['2']);
    });

    test('dollar quoted string', () {
      final desc = InternalQueryDescription.map(
        r"SELECT $foo$ This is a string literal $foo that still hasn't ended here $foo$, @1",
      );

      expect(
        desc.transformedSql,
        r"SELECT $foo$ This is a string literal $foo that still hasn't ended here $foo$, $1",
      );
      expect(desc.namedVariables?.keys, ['1']);
    });

    test('invalid dollar quoted string', () {
      final desc = InternalQueryDescription.map(r'SELECT $foo @1');
      expect(desc.transformedSql, r'SELECT $foo $1');
      expect(desc.namedVariables?.keys, ['1']);
    });

    // https://www.postgresql.org/docs/current/functions-json.html
    final operators = ['@>', '<@', '@?', '@@'];
    for (final operator in operators) {
      test('can use $operator', () {
        final desc = InternalQueryDescription.map('SELECT @foo $operator @bar');
        expect(desc.transformedSql, 'SELECT \$1 $operator \$2');
        expect(desc.namedVariables?.keys, ['foo', 'bar']);
      });
    }
  });

  group('throws', () {
    test('for variable with empty type name', () {
      expect(() => InternalQueryDescription.map('SELECT @var: FROM foo'),
          throwsFormatException);
    });

    test('for invalid type name', () {
      expect(
          () => InternalQueryDescription.map('SELECT @var:nosuchtype FROM foo'),
          throwsFormatException);
    });

    test('for missing variable', () {
      expect(
        () => InternalQueryDescription.map('SELECT @foo').bindParameters({}),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Missing variable for `foo`',
        )),
      );
    });

    test('for superfluous variables', () {
      expect(
        () => InternalQueryDescription.map('SELECT @foo:int4').bindParameters({
          'foo': 3,
          'X': 'Y',
          'Y': 'Z',
        }),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Contains superfluous variables: X, Y',
        )),
      );
    });
  });
}
