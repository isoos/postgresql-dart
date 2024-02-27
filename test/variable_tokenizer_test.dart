import 'package:postgres/postgres.dart';
import 'package:postgres/src/v3/query_description.dart';
import 'package:test/test.dart';

void main() {
  test('can declare variables', () {
    final desc =
        InternalQueryDescription.named('SELECT @x:int8, @y:boolean, @z');

    expect(desc.transformedSql, r'SELECT $1, $2, $3');
    expect(
      desc.namedVariables,
      {'x': 1, 'y': 2, 'z': 3},
    );
    expect(desc.parameterTypes, [
      Type.bigInteger, // x
      Type.boolean, // y
      null, // z, didn't have a specified type
    ]);

    expect(() => desc.bindParameters(null), throwsArgumentError);

    expect(
      desc.bindParameters({'x': 4, 'y': true, 'z': TypedValue(Type.text, 'z')}),
      [
        TypedValue(Type.bigInteger, 4),
        TypedValue(Type.boolean, true),
        TypedValue(Type.text, 'z'),
      ],
    );
    expect(desc.bindParameters({'x': 4, 'y': true, 'z': 'z'}), [
      TypedValue(Type.bigInteger, 4),
      TypedValue(Type.boolean, true),
      TypedValue(Type.unspecified, 'z'),
    ]);

    // Make sure we can still bind by index
    expect(
      desc.bindParameters([1, true, TypedValue(Type.text, 'z')]),
      [
        TypedValue(Type.bigInteger, 1),
        TypedValue(Type.boolean, true),
        TypedValue(Type.text, 'z'),
      ],
    );
    expect(
      desc.bindParameters([1, true, 3]),
      [
        TypedValue(Type.bigInteger, 1),
        TypedValue(Type.boolean, true),
        TypedValue(Type.unspecified, 3),
      ],
    );
  });

  test('can declare variables by index', () {
    final desc = InternalQueryDescription.indexed(
        'SELECT ?:int8, ?3:boolean, ?2',
        substitution: '?');

    expect(desc.transformedSql, r'SELECT $1, $3, $2');
    expect(desc.namedVariables, isNull);
    expect(desc.parameterTypes, [Type.bigInteger, null, Type.boolean]);

    expect(() => desc.bindParameters(null), throwsArgumentError);
    expect(
      desc.bindParameters([4, TypedValue(Type.text, 'z'), true]),
      [
        TypedValue(Type.bigInteger, 4),
        TypedValue(Type.text, 'z'),
        TypedValue(Type.boolean, true),
      ],
    );
    expect(desc.bindParameters([4, 'z', true]), [
      TypedValue(Type.bigInteger, 4),
      TypedValue(Type.unspecified, 'z'),
      TypedValue(Type.boolean, true),
    ]);
  });

  test('can use the same variable more than once', () {
    final desc = InternalQueryDescription.named(
        'SELECT * FROM foo WHERE a = @x OR bar = @y OR b = @x');
    expect(desc.transformedSql,
        r'SELECT * FROM foo WHERE a = $1 OR bar = $2 OR b = $1');
    expect(desc.namedVariables?.keys, ['x', 'y']);
  });

  test('indexed can use same variable more than once', () {
    final indexed = InternalQueryDescription.indexed(
        'SELECT * FROM foo WHERE a = @ OR bar = @ OR b = @1');
    expect(indexed.transformedSql,
        r'SELECT * FROM foo WHERE a = $1 OR bar = $2 OR b = $1');
    expect(indexed.namedVariables, isNull);
    expect(indexed.parameterTypes, hasLength(2));
  });

  test('can use custom variable symbol', () {
    final desc = InternalQueryDescription.named(
        'SELECT * FROM foo WHERE a = :x:int8',
        substitution: ':');
    expect(desc.transformedSql, r'SELECT * FROM foo WHERE a = $1');
    expect(desc.namedVariables?.keys, ['x']);
    expect(desc.parameterTypes, [Type.bigInteger]);
  });

  group('can use : substitution symbol and cast operator together', () {
    test('simple', () {
      final desc = InternalQueryDescription.named(
          'SELECT id::text FROM foo WHERE a = :x:int8::int',
          substitution: ':');
      expect(
          desc.transformedSql, r'SELECT id::text FROM foo WHERE a = $1::int');
      expect(desc.namedVariables?.keys, ['x']);
      expect(desc.parameterTypes, [Type.bigInteger]);
    });
    test('with comment', () {
      final desc = InternalQueryDescription.named(
          'SELECT id /**/ :: /**/ text, b::\nint8 FROM foo WHERE a = :x:int8/**/::/**/int8',
          substitution: ':');
      expect(desc.transformedSql,
          'SELECT id  ::  text, b::\nint8 FROM foo WHERE a = \$1::int8');
      expect(desc.namedVariables?.keys, ['x']);
      expect(desc.parameterTypes, [Type.bigInteger]);
    });
  });

  test('finds correct end for string literal', () {
    final desc = InternalQueryDescription.named(r"SELECT e'@a\\' @b");
    expect(desc.transformedSql, r"SELECT e'@a\\' $1");
    expect(desc.namedVariables?.keys, ['b']);
  });

  group('VARCHAR(x)', () {
    test('accept with some length', () {
      final desc = InternalQueryDescription.named('SELECT @x:_varchar(10), 0');
      expect(desc.transformedSql, r'SELECT $1, 0');
      expect(desc.namedVariables, {'x': 1});
      expect(desc.parameterTypes, [Type.varCharArray]);
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
          () => InternalQueryDescription.named('SELECT $snippet'),
          throwsFormatException,
          reason: snippet,
        );
        expect(
          () => InternalQueryDescription.named('SELECT $snippet, 0'),
          throwsFormatException,
          reason: '$snippet, 0',
        );
      }
    });
  });

  group('ignores', () {
    test('line comments', () {
      final desc = InternalQueryDescription.named('SELECT @1, -- @2 \n @3');
      expect(desc.transformedSql, r'SELECT $1,  $2');
      expect(desc.namedVariables?.keys, ['1', '3']);
    });

    test('block comments', () {
      final desc = InternalQueryDescription.named(
          'SELECT @1 /* this is ignored: @2 */, @3');
      expect(desc.transformedSql, r'SELECT $1 , $2');
      expect(desc.namedVariables?.keys, ['1', '3']);
    });

    test('string literals', () {
      final desc = InternalQueryDescription.named(
          "SELECT @1, 'isn''t a variable: @2', @3");
      expect(desc.transformedSql, r"SELECT $1, 'isn''t a variable: @2', $2");
      expect(desc.namedVariables?.keys, ['1', '3']);
    });

    test('string literals with C-style escapes', () {
      final desc = InternalQueryDescription.named(
          r"SELECT @1, E'isn\'t a variable: @2', @3");
      expect(desc.transformedSql, r"SELECT $1, E'isn\'t a variable: @2', $2");
      expect(desc.namedVariables?.keys, ['1', '3']);
    });

    test('strings with unicode escapes', () {
      final desc = InternalQueryDescription.named(r"U&'d\0061t@1\+000061', @2");
      expect(desc.transformedSql, r"U&'d\0061t@1\+000061', $1");
      expect(desc.namedVariables?.keys, ['2']);
    });

    test('identifiers', () {
      final desc = InternalQueryDescription.named('SELECT @1 AS "@2", @3');
      expect(desc.transformedSql, r'SELECT $1 AS "@2", $2');
      expect(desc.namedVariables?.keys, ['1', '3']);
    });

    test('identifiers with unicode escapes', () {
      final desc =
          InternalQueryDescription.named(r'SELECT U&"d\0061t@1\+000061", @2');
      expect(desc.transformedSql, r'SELECT U&"d\0061t@1\+000061", $1');
      expect(desc.namedVariables?.keys, ['2']);
    });

    test('dollar quoted string', () {
      final desc = InternalQueryDescription.named(
        r"SELECT $foo$ This is a string literal $foo that still hasn't ended here $foo$, @1",
      );

      expect(
        desc.transformedSql,
        r"SELECT $foo$ This is a string literal $foo that still hasn't ended here $foo$, $1",
      );
      expect(desc.namedVariables?.keys, ['1']);
    });

    test('invalid dollar quoted string', () {
      final desc = InternalQueryDescription.named(r'SELECT $foo @1');
      expect(desc.transformedSql, r'SELECT $foo $1');
      expect(desc.namedVariables?.keys, ['1']);
    });

    // https://www.postgresql.org/docs/current/functions-json.html
    final operators = ['@>', '<@', '@?', '@@'];
    for (final operator in operators) {
      test('can use $operator', () {
        final desc =
            InternalQueryDescription.named('SELECT @foo $operator @bar');
        expect(desc.transformedSql, 'SELECT \$1 $operator \$2');
        expect(desc.namedVariables?.keys, ['foo', 'bar']);
      });
    }
  });

  group('throws', () {
    test('for variable with empty type name', () {
      expect(() => InternalQueryDescription.named('SELECT @var: FROM foo'),
          throwsFormatException);
    });

    test('for invalid type name', () {
      expect(
          () =>
              InternalQueryDescription.named('SELECT @var:nosuchtype FROM foo'),
          throwsFormatException);
    });

    test('for missing variable', () {
      expect(
        () => InternalQueryDescription.named('SELECT @foo').bindParameters({}),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Missing variable for `foo`',
        )),
      );
    });

    test('for missing variable indexed', () {
      expect(
        () => InternalQueryDescription.indexed('SELECT @').bindParameters([]),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Expected 1 parameters, got 0',
        )),
      );
    });

    test('when using map with indexed', () {
      expect(
        () => InternalQueryDescription.indexed('SELECT @')
            .bindParameters({'1': 'foo'}),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Maps are only supported by `Sql.named`',
        )),
      );
    });

    test('for superfluous variables', () {
      expect(
        () =>
            InternalQueryDescription.named('SELECT @foo:int4').bindParameters({
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
