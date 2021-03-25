# Changelog

## 2.3.1

- Added support for types varchar, point, integerArray, doubleArray, textArray and jsonArray.

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
