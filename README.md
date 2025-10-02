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

## Connection string URLs

The package supports connection strings for both single connections and connection pools:

```dart
await Connection.openFromUrl('postgresql://localhost/mydb');
await Connection.openFromUrl(
  'postgresql://user:pass@db.example.com:5432/production?sslmode=verify-full'
);
await Connection.openFromUrl(
  'postgresql://localhost/mydb?connect_timeout=10&query_timeout=60'
);
Pool.withUrl(
  'postgresql://localhost/mydb?max_connection_count=10&max_connection_age=3600'
);
```

### URL Format

`postgresql://[userspec@][hostspec][:port][/dbname][?paramspec]`

- **Scheme**: `postgresql://` or `postgres://`
- **User**: `username` or `username:password`
- **Host**: hostname or IP address (defaults to `localhost`)
- **Port**: port number (defaults to `5432`)
- **Database**: database name (defaults to `postgres`)
- **Parameters**: query parameters (see below)

### Standard Parameters

These parameters are supported by `Connection.openFromUrl()`:

| Parameter | Type | Description | Example Values |
|-----------|------|-------------|----------------|
| `application_name` | String | Sets the application name | `application_name=myapp` |
| `client_encoding` | String | Character encoding | `UTF8`, `LATIN1` |
| `connect_timeout` | Integer | Connection timeout in seconds | `connect_timeout=30` |
| `sslmode` | String | SSL mode | `disable`, `require`, `verify-ca`, `verify-full` |
| `sslcert` | String | Path to client certificate | `sslcert=/path/to/cert.pem` |
| `sslkey` | String | Path to client private key | `sslkey=/path/to/key.pem` |
| `sslrootcert` | String | Path to root certificate | `sslrootcert=/path/to/ca.pem` |
| `replication` | String | Replication mode | `database` (logical), `true`/`physical`, `false`/`no_select` (none) |
| `query_timeout` | Integer | Query timeout in seconds | `query_timeout=300` |

### Pool-Specific Parameters

These additional parameters are supported by `Pool.withUrl()`:

| Parameter | Type | Description | Example Values |
|-----------|------|-------------|----------------|
| `max_connection_count` | Integer | Maximum number of concurrent connections | `max_connection_count=20` |
| `max_connection_age` | Integer | Maximum connection lifetime in seconds | `max_connection_age=3600` |
| `max_session_use` | Integer | Maximum session duration in seconds | `max_session_use=600` |
| `max_query_count` | Integer | Maximum queries per connection | `max_query_count=1000` |

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
