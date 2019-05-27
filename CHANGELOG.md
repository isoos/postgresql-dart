# Changelog

## 2.0.0-dev1

- Restricted field access on [PostgreSQLConnection].
- Connection-level default query timeout.
- Option to specify timeout for the transaction's `"COMMIT"` query.
- Optimized byte buffer parsing and construction with `package:buffer`.
- Hardened codebase with `package:pedantic` and additional lints.
- Updated codebase to Dart 2.2.
- `PostgreSQLResult` and `PostgreSQLResultRow` as the return value of a query.
  - Returned lists are protected with `UnmodifiableListView`.
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
