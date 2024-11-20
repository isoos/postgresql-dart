# Changelog

## 3.4.4

- Fix: explicit closing of prepared statement portals in transactions to release table locks. [#393](https://github.com/isoos/postgresql-dart/pull/393)

## 3.4.3

- Fix: prevent hanging state by forwarding protocol-level parsing errors into the message stream.

## 3.4.2

- Fix: When a transaction is rolled back, do not expose the exception on rollback, rather the original exception from the transaction.

## 3.4.1

- Do not allow exceptions escape when closing broken connection. [#384](https://github.com/isoos/postgresql-dart/pull/384) by [pulyaevskiy](https://github.com/pulyaevskiy).

## 3.4.0

- `Connection.info` (through `ConnectionInfo` class) exposes read-only connection-level information,
  e.g. acessing access server-provided parameter status values.
- Support for binary `pgoutput` replication by [wolframm](https://github.com/Wolframm-Activities-OU).
- **Allowing custom type codecs**:
  - `Codec` interface is used for encoding/decoding value by type OIDs or Dart values.
  - `Codec.encode` and `Codec.decode` gets a reference to `CodecContext` which provides
     access to `encoding`, observed runtime parameters and the `TypeRegistry`.
  - `EncoderFn` value converter for generic Dart object -> Postgres-encoded bytes
    (for values where type is not specified).
  - `DatabaseInfo` tracks information about relations and oids (currently limited to `RelationMessage` caching).
- **Timeout-related behaviour changes**, may be breaking in some cases:
  - Preparing/executing a stamement on the main connection while in a `runTx` callback will throw an exception.
  - Setting `timeout` will try to actively cancel the current statement using a new connection.
  - `ServerException` may be transformed into `_PgQueryCancelledException` which is both `PgException` and `TimeoutException` (but no longer `ServerException`).
- **API deprecations**:
  - Deprecated `TupleDataColumn.data`, use `.value` instead (for binary protocol messages).
  - Deprecated some logical replication message parsing method.
  - Removed `@internal`-annotated methods from the public API of `ServerException` and `Severity`.

## 3.3.0

**Removed legacy v2 APIs.** These APIs were meant to be removed in `3.1.0`, but
were kept for a bit longer, as they didn't have any drawback to be around.
However, a planned redesign of the type customization would require to touch the
v2 codebase and it is not worth the effort to keep it much longer.

## 3.2.1

- Added or fixed decoders support for `QueryMode.simple`:
  `double`, `real`, `timestampWithTimezone`, `timestampWithoutTimezone`,
  `date`, `numeric`, `json`, `jsonb` [#338](https://github.com/isoos/postgresql-dart/pull/338) by [pst9354](https://github.com/pst9354).

## 3.2.0

- Support for `tsvector` and `tsquery` types.
- `ResultRow.isSqlNull(int)` returns true if the column's value was SQL `NULL`.
- `TypedValue.isSqlNull` indicates SQL `NULL` (vs. JSON `null`).

## 3.1.2

- `ConnectionSettings.onOpen` callback to initialize a new connection and set
  connection-level variables.

## 3.1.1

- Use ':' (colon) for substitution and cast operator together [#309](https://github.com/isoos/postgresql-dart/pull/309) by [xvrh](https://github.com/xvrh).

## 3.1.0

Added the following PostgreSQL builtin types:
- Geometric types `line`, `lseg`, `path`, `polygon`, `box`, `circle`
- Range types `int4range`, `int8range`, `daterange`, `tsrange`, `tstzrange`
- Time type `time`
- Array types `_int2`, `_date`, `_time`, `_timestamp`, `_timestamptz`, `_uuid`

Huge thanks for [#294](https://github.com/isoos/postgresql-dart/pull/294) by [wolframm](https://github.com/Wolframm-Activities-OU).

## 3.0.8

- Properly react to connection losses by reporting the database connection as
  closed.

## 3.0.7

- Allow cleartext passwords when secure connection is used. ([#283](https://github.com/isoos/postgresql-dart/pull/283) by [simolus3](https://github.com/simolus3))

## 3.0.6

- Allow passing a `SecurityContext` when opening postgres connections.

## 3.0.5

- Support for type `char`/`character`/`bpchar`.

## 3.0.4

- Fix: SSL connection problem handler.

## 3.0.3

- Using const for ConnectionSettings, SessionSettings and PoolSettings classes. ([#267](https://github.com/isoos/postgresql-dart/pull/267) by [Gerrel](https://github.com/Gerrel))
- Parsing of `Sql.indexed` and `Sql.named` happens when the `Connection` starts
  to interpret it. Errors with unknown type names are thrown in this later step.

## 3.0.2

- Fix: Dispose disconnected pool `Connection`s. ([#260](https://github.com/isoos/postgresql-dart/pull/260) by [nehzata](https://github.com/nehzata)).
- Deprecated `ParseMessage` constructor's `types` argument, use `typeOids` instead.
  (As most users don't access this directly, it will be removed in `3.1.0`).

## 3.0.1

- Fix: do not allow `execute` after closing the `Connection`.
- `Session.runTx()` supports rolling back the transaction through `TxSession.rollback()`
  (otherwise any exception has the same effect, but callers need to catch it).
- Supporting more type aliases, including `serial4`, `serial8`, `integer`...
- Deprecated all of v2 API, legacy fallback will be removed in next minor version (`3.1.0`).

## 3.0.0

New features:

- New API (better names and consistency).
- New SQL parsing and configurable query substitutions.
- Integrated connection pooling.
- A somewhat-compatible legacy API support to help migrations (will be removed in `3.1.0`).

### BREAKING CHANGES

The package had a partial rewrite affecting public client API and internal
behaviour, keeping most of the wire protocol handling from the old version.

**Users of this package must rewrite and test their application when upgrading.**

Notable breaking behaviour changes:

  - Simple query protocol allows sending queries to the server without
    awaiting on the result. The new implementation queues these request
    on the client instead.
  - Table name OIDs are not fetched or cached, this information from the
    result schema is absent, also causing `mappedResultsQuery` to be
    removed from the new API.
  - Queries are not cached implicitly, explicit prepared statements can be
    used instead.
  - `interval` values are returned as `Interval` type instead of `Duration`.
  - A newly added `UndecodedBytes` instances are returned when the package does
    not know or has not implemented the appropriate type decoding yet.
    Previously these values were auto-encoded to `String` and if that failed
    the `Uint8List` were used.
  - Types, fields and parameter names may have been renamed to be more
    consistent or more aligned with the Dart naming guides.

### Legacy compatibility layer

`package:postgres/legacy.dart` provides a somewhat backwards-compatible API
via the `PostgreSQLConnection.withV3()` constructor. Many features, including
the ones mentioned above are missing and/or throw `UnimplementedError` when called.

### Migration

  - You may use the legacy compatibility layer to check if your code relies on
    any of the above mentioned feature, rewrite if needed.
  - Start using the new API, incrementally, when possible.
  - For most queries, you may use `Sql.named('SELECT ...')` to keep the default
    name- and `Map`-based query `@variable`` substitution, or you may use the
    raw `$1` version (with 1-based indexes).
  - Always write tests.

If you have any issues with migration or with the new behavior, please open an
issue on the package's GitHub issue tracker or discussions.

### Thanks

The rewrite happened because of many contributions (including code, comments or
criticism) on the new direction and design. I'd like to call out especially to
[simolus3](https://github.com/simolus3) and [osaxma](https://github.com/osaxma),
who helped to push forward.

## 3.0.0-beta.2

*see the latest 3.0.0 (pre)release*

## 3.0.0-beta.1

*see the latest 3.0.0 (pre)release*

## 3.0.0-alpha.1

*see the latest 3.0.0 (pre)release*

## 2.6.3

- Allow `encoding` to be specified for connections. The setting will be used for all connection-related string conversions.
- Allow generic `List` type as substitution values in binary encoding (as long as the inner type matches).
- Refactor: replaced `UTF8BackedString` with generic encoding (not complete).
- Breaking change in `package:postgres/messages.dart`: default constructors made internal, parsing is done with more efficient reader.

## 2.6.2

- Improved (experimental) v3 implementation.
  [#98](https://github.com/isoos/postgresql-dart/pull/98) and
  [#102](https://github.com/isoos/postgresql-dart/pull/102) by [simolus3](https://github.com/simolus3).

## 2.6.1

- Added support for bigInt (int8) arrays. [#41](https://github.com/isoos/postgresql-dart/pull/88) by [schultek](https://github.com/schultek).

## 2.6.0

- Updated to `package:lints`.
- Adding lowerCase values to `AuthenticationScheme`.
- Add new `package:postgres/postgres_v3_experimental.dart` library as a preview.
  It exposes the postgres client under a new API that will replace the current
  one in version `3.0.0` of this package.
  At the moment, the new library is experimental and not fully implemented. Until the
  actual `3.0.0` release, the new APIs might change without a breaking version.

## 2.5.2

- Connecting without a password for non-trusted users throws an exception instead of timing out [#68](https://github.com/isoos/postgresql-dart/pull/68) by [osaxma](https://github.com/osaxma).

## 2.5.1

- Use `substitutionValues` with `useSimpleQueryProtocol` [#62](https://github.com/isoos/postgresql-dart/pull/62) by [osaxma](https://github.com/osaxma)

## 2.5.0

- Added Support for Streaming Replication Protocol which included the following changes:
  - Replication Mode Messages Handling. [#58](https://github.com/isoos/postgresql-dart/pull/58) by [osaxma](https://github.com/osaxma)
  - Add new message types for replication. [#57](https://github.com/isoos/postgresql-dart/pull/57) by [osaxma](https://github.com/osaxma)
  - Add connection configuration for Streaming Replication Protocol. [#56](https://github.com/isoos/postgresql-dart/pull/56) by [osaxma](https://github.com/osaxma)
  - Raise the min sdk version to support enhanced enums. [#55](https://github.com/isoos/postgresql-dart/pull/55) by [osaxma](https://github.com/osaxma)
  - Add LSN type and time conversion to and from ms-since-Y2K. [#53](https://github.com/isoos/postgresql-dart/pull/53) by [osaxma](https://github.com/osaxma)
  - Fix affected rows parsing in CommandCompleteMessage. [#52](https://github.com/isoos/postgresql-dart/pull/52) by [osaxma](https://github.com/osaxma)
  - Introduced new APIs to `PostgreSQLConnection`: `addMessage` to send client messages, `messages` stream to listen to server messages & `useSimpleQueryProtocol` option in `query` method. [#51](https://github.com/isoos/postgresql-dart/pull/51) by [osaxma](https://github.com/osaxma)

## 2.4.6

- Fix crash when manually issuing a transaction statement like `BEGIN` without
  using the high-level transaction APIs. [#47](https://github.com/isoos/postgresql-dart/pull/47) by [simolus3](https://github.com/simolus3).

## 2.4.5

- Added support for boolean arrays. [#41](https://github.com/isoos/postgresql-dart/pull/41) by [slightfoot](https://github.com/slightfoot).

## 2.4.4

- Added support for varchar arrays. [#39](https://github.com/isoos/postgresql-dart/pull/39) by [paschalisp](https://github.com/paschalisp).

## 2.4.3

- Support for clear text passwords using a boolean parameter in connection as 'allowClearTextPassword' to activate / deactivate the feature. [#20](https://github.com/isoos/postgresql-dart/pull/20).

## 2.4.2

- Include original stacktrace when query fails.
  ([#15](https://github.com/isoos/postgresql-dart/pull/15) by [davidmartos96](https://github.com/davidmartos96))

## 2.4.1+2

- Fix error when sending json data with `execute()` [#11](https://github.com/isoos/postgresql-dart/pull/11)

## 2.4.1+1

- Fix error when passing `allowReuse: null` into `query()` [#8](https://github.com/isoos/postgresql-dart/pull/8)

## 2.4.1

- Support for type `interval`, [#10](https://github.com/isoos/postgresql-dart/pull/10).

## 2.4.0

- Support for type `numeric` / `decimal` ([#7](https://github.com/isoos/postgresql-dart/pull/7), [#9](https://github.com/isoos/postgresql-dart/pull/9)).
- Support SASL / SCRAM-SHA-256 Authentication, [#6](https://github.com/isoos/postgresql-dart/pull/6).

## 2.3.2

- Expose `ColumnDescription.typeId`.

## 2.3.1

- Added support for types `varchar`, `point`, `integerArray`, `doubleArray`, `textArray` and `jsonArray`.
  (Thanks to [schultek](https://github.com/schultek), [#3](https://github.com/isoos/postgresql-dart/pull/3))

## 2.3.0

- Finalized null-safe release.

## 2.3.0-null-safety.2

- Fixing query API optional parameters.

## 2.3.0-null-safety.1

- Updated public API to always return non-nullable results.
- **BREAKING CHANGE**: unknown mapped table name is no longer `null`, it is empty string (`''`).

## 2.3.0-null-safety.0

- Migrate to null safety. (Thanks to [j4qfrost](https://github.com/j4qfrost), [#153](https://github.com/stablekernel/postgresql-dart/pull/153)).
- Documentation fix (by [saward](https://github.com/saward)).

## 2.2.0

- Supporting Unix socket connections. (Thanks to [grillbiff](https://github.com/grillbiff),
  [#124](https://github.com/stablekernel/postgresql-dart/pull/124))
- Preparation for custom type converters.
- Added rowsAffected to PostgreSQLResult. (Thanks to [arturaz](https://github.com/arturaz),
  [#143](https://github.com/stablekernel/postgresql-dart/pull/143))

## 2.1.1

- Fix `RuneIterator.current` use, which no longer returns `null` in 2.8 SDK.

## 2.1.0

- Missing substitution value no longer throws `FormatException`.
  [More details in the GitHub issue.](https://github.com/stablekernel/postgresql-dart/issues/57)

## 2.0.0

- Fixed startup packet length when username is null (#111).
- Finalized dev release.

## 2.0.0-dev1.0

- Restricted field access on [PostgreSQLConnection].
- Connection-level default query timeout.
- Option to specify timeout for the transaction's `"COMMIT"` query.
- Optimized byte buffer parsing and construction with `package:buffer`.
- Hardened codebase with `package:pedantic` and additional lints.
- Updated codebase to Dart 2.2.
- `PostgreSQLResult` and `PostgreSQLResultRow` as the return value of a query.
  - Returned lists are protected with `UnmodifiableListView`.
  - Exposing column metadata through `ColumnDescription`.
  - row-level `toTableColumnMap` and `toColumnMap`
- `PostgreSQLConnection` and `_TransactionProxy` share the OID cache.
- default value for `query(allowReuse = true)` is set only in the implementation method.

**Breaking behaviour**

- Table OIDs are always resolved to table names (and not only with mapped queries).

## 1.0.2
- Add connection queue size

## 1.0.1

- Prevent the table name resolution of OIDs <= 0.

## 1.0.0

- Adds support for Dart 2

## 0.9.9

- Add full support for `UUID` columns.

## 0.9.8

- Preserve error stacktrace on various query or transaction errors.
- Read support for `BYTEA` columns.

## 0.9.7

- Adds `Connection.mappedResultsQuery` to return query results as a `Map` with keys for table and column names.

## 0.9.6

- Adds `Connection.notifications` to listen for `NOTIFY` events (thanks @andrewst)
- Adds better error reporting.
- Adds support for JSONB columns.
- Fixes issue when encoding UTF16 characters (thanks @andrewst)

## 0.9.5

- Allow connect via SSL.

## 0.9.4

- Fixed issue with buffer length

## 0.9.3

- Fixed issue with UTF8 encoding

## 0.9.2

- Bump for documentation

## 0.9.1

- Added transactions: PostgreSQLConnection.transaction and PostgreSQLConnection.cancelTransaction.

## 0.9.0

- Initial version
