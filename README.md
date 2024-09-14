# PostgreSQL client

[![CI](https://github.com/isoos/postgresql-dart/actions/workflows/dart.yml/badge.svg)](https://github.com/isoos/postgresql-dart/actions/workflows/dart.yml)

A library for connecting to and querying PostgreSQL databases (see [Postgres Protocol](https://www.postgresql.org/docs/13/protocol-overview.html)). This driver uses the more efficient and secure extended query format of the PostgreSQL protocol.

## Usage

Create a `Connection`:

```dart
  final conn = await Connection.open(Endpoint(
    host: 'localhost',
    database: 'postgres',
    username: 'user',
    password: 'pass',
  ));
```

Execute queries with `execute`:

```dart
  final result = await conn.execute("SELECT 'foo'");
  print(result[0][0]); // first row and first field
```

Named parameters, returning rows as map of column names:

```dart
  final result = await conn.execute(
    Sql.named('SELECT * FROM a_table WHERE id=@id'),
    parameters: {'id': 'xyz'},
  );
  print(result.first.toColumnMap());
```

Execute queries in a transaction:

```dart
  await conn.runTx((s) async {
    final rs = await s.execute('SELECT count(*) FROM foo');
    await s.execute(
      r'UPDATE a_table SET totals=$1 WHERE id=$2',
      parameters: [rs[0][0], 'xyz'],
    );
  });
```

See the API documentation: https://pub.dev/documentation/postgres/latest/

## Connection pooling

The library supports connection pooling (and masking the connection pool as
regular session executor).

## Custom type codecs

The library supports registering custom type codecs (and generic object encoders)
through the`ConnectionSettings.typeRegistry`.

## Streaming replication protocol

The library supports connecting to PostgreSQL using the [Streaming Replication Protocol][].
See [Connection][] documentation for more info.
An example can also be found at the following repository: [postgresql-dart-replication-example][]

[Streaming Replication Protocol]: https://www.postgresql.org/docs/13/protocol-replication.html
[Connection]: https://pub.dev/documentation/postgres/latest/postgres/Connection/Connection.html
[postgresql-dart-replication-example]: https://github.com/osaxma/postgresql-dart-replication-example

## Other notes

This library originally started as [StableKernel's postgres library](https://github.com/stablekernel/postgresql-dart),
but got a full API overhaul and partial rewrite of the internals.

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/isoos/postgresql-dart/issues
