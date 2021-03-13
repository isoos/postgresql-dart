# postgres

[![CI](https://github.com/isoos/postgresql-dart/actions/workflows/dart.yml/badge.svg)](https://github.com/isoos/postgresql-dart/actions/workflows/dart.yml)

A library for connecting to and querying PostgreSQL databases.

This driver uses the more efficient and secure extended query format of the PostgreSQL protocol.

## Usage

Create `PostgreSQLConnection`s and `open` them:

```dart
var connection = PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");
await connection.open();
```

Execute queries with `query`:

```dart
List<List<dynamic>> results = await connection.query("SELECT a, b FROM table WHERE a = @aValue", substitutionValues: {
    "aValue" : 3
});

for (final row in results) {
  var a = row[0];
  var b = row[1];

} 
```

Return rows as maps containing table and column names:

```dart
List<Map<String, Map<String, dynamic>>> results = await connection.mappedResultsQuery(
  "SELECT t.id, t.name, u.name FROM t LEFT OUTER JOIN u ON t.id=u.t_id");

for (final row in results) {
  var tID = row["t"]["id"];
  var tName = row["t"]["name"];
  var uName = row["u"]["name"];
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

## Features and bugs

This library is a fork of [StableKernel's postgres library](https://github.com/stablekernel/postgresql-dart).

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/isoos/postgresql-dart/issues
