# Changelog

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
