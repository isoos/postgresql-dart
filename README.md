# postgres

[![CI](https://github.com/isoos/postgresql-dart/actions/workflows/dart.yml/badge.svg)](https://github.com/isoos/postgresql-dart/actions/workflows/dart.yml)

A library for connecting to and querying PostgreSQL databases (see [Postgres Protocol](https://www.postgresql.org/docs/13/protocol-overview.html)).

This driver uses the more efficient and secure extended query format of the PostgreSQL protocol.

## Usage

Create `PostgreSQLConnection`s and `open` them:

```dart
  final endpoint = PgEndpoint(
    host: 'localhost',
    database: 'postgres',
    username: 'user',
    password: 'pass',
  );
  final conn = await PgConnection.open(endpoint);
```

Execute queries with `query`:

```dart
final results = await conn.execute('SELECT a, b FROM table WHERE a = @aValue', parameters: {
    "aValue" : 3
});

for (final row in results) {
  final col1 = row[0];
  final col2 = row[1];
}
```

Return rows as maps containing column names:

```dart
final results = await conn.execute('SELECT t.id, t.name, u.name FROM t');

for (final row in results) {
  print(row.toColumnMap());
}
```

Execute queries in a transaction:

```dart
await connection.transaction((ctx) async {
    var result = await ctx.query("SELECT id FROM table");
    await ctx.query("INSERT INTO table (id) VALUES (@a:int4)", substitutionValues: {
        "a" : result.last[0] + 1
    });
});
```

See the API documentation: https://pub.dev/documentation/postgres/latest/

## Additional Capabilities

The library supports connecting to PostgreSQL using the [Streaming Replication Protocol][].
See [PostgreSQLConnection][] documentation for more info.
An example can also be found at the following repository: [postgresql-dart-replication-example][]

[Streaming Replication Protocol]: https://www.postgresql.org/docs/13/protocol-replication.html
[PostgreSQLConnection]: https://pub.dev/documentation/postgres/latest/postgres/PostgreSQLConnection/PostgreSQLConnection.html
[postgresql-dart-replication-example]: https://github.com/osaxma/postgresql-dart-replication-example

## Features and bugs

This library is a fork of [StableKernel's postgres library](https://github.com/stablekernel/postgresql-dart).

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/isoos/postgresql-dart/issues
