import 'dart:async';

import '../types.dart';

import 'connection.dart';
import 'query.dart';
import 'substituter.dart';

abstract class PostgreSQLExecutionContext {
  /// Returns this context queue size
  int get queueSize;

  /// Executes a query on this context.
  ///
  /// This method sends the query described by [fmtString] to the database and returns a [Future] whose value is the returned rows from the query after the query completes.
  /// The format string may contain parameters that are provided in [substitutionValues]. Parameters are prefixed with the '@' character. Keys to replace the parameters
  /// do not include the '@' character. For example:
  ///
  ///         connection.query("SELECT * FROM table WHERE id = @idParam", {"idParam" : 2});
  ///
  /// The type of the value is inferred by default, but should be made more specific by adding ':type" to the parameter pattern in the format string. For example:
  ///
  ///         connection.query("SELECT * FROM table WHERE id = @idParam:int4", {"idParam" : 2});
  ///
  /// Available types are listed in [PostgreSQLFormatIdentifier.typeStringToCodeMap]. Some types have multiple options. It is preferable to use the [PostgreSQLFormat.id]
  /// function to add parameters to a query string. This method inserts a parameter name and the appropriate ':type' string for a [Type].
  ///
  /// If successful, the returned [Future] completes with a [List] of rows. Each is row is represented by a [List] of column values for that row that were returned by the query.
  ///
  /// By default, instances of this class will reuse queries. This allows significantly more efficient transport to and from the database. You do not have to do
  /// anything to opt in to this behavior, this connection will track the necessary information required to reuse queries without intervention. (The [fmtString] is
  /// the unique identifier to look up reuse information.) You can disable reuse by passing false for [allowReuse].
  ///
  /// [useSimpleQueryProtocol] indicates that the query will be executed using
  /// the [Simple Query Protocol][]. This is similar to runing [execute] but
  /// instead of receiving the `affectedRowCount` only, this method will return
  /// [PostgreSQLResult] which contains `affectedRowCount` in addition to any
  /// data returned by the executed statement.
  ///
  /// It's important to understand that when [useSimpleQueryProtocol] is `true`,
  /// all values will be of type [String] even if they have different type in the
  /// database. For instance, the value of an `int4` column will be returned as
  /// a [String] instead of an [int].
  ///
  /// Setting [useSimpleQueryProtocol] to `true` is mainly useful for when the
  /// connection is established using the Streaming Replication Protocol. When
  /// the connection is in replication mode, the default Extended Query Protocol
  /// cannot be used as the database will throw an error and drop the connection.
  /// In other words, only the Simple Query Protocol can be used with Streaming
  /// Replication Protocol.
  ///
  /// [Simple Query Protocol]: https://www.postgresql.org/docs/current/protocol-flow.html#id-1.10.5.7.4
  Future<PostgreSQLResult> query(String fmtString,
      {Map<String, dynamic>? substitutionValues,
      bool? allowReuse,
      int? timeoutInSeconds,
      bool? useSimpleQueryProtocol});

  /// Executes a query on this context.
  ///
  /// This method sends a SQL string to the database this instance is connected to. Parameters can be provided in [fmtString], see [query] for more details.
  ///
  /// This method returns the number of rows affected and no additional information. This method uses the least efficient and less secure command
  /// for executing queries in the PostgreSQL protocol; [query] is preferred for queries that will be executed more than once, will contain user input,
  /// or return rows.
  Future<int> execute(String fmtString,
      {Map<String, dynamic>? substitutionValues, int? timeoutInSeconds});

  /// Cancels a transaction on this context.
  ///
  /// If this context is an instance of [PostgreSQLConnection], this method has no effect. If the context is a transaction context (passed as the argument
  /// to [PostgreSQLConnection.transaction]), this will rollback the transaction.
  void cancelTransaction({String? reason});

  /// Executes a query on this connection and returns each row as a [Map].
  ///
  /// This method constructs and executes a query in the same way as [query], but returns each row as a [Map].
  ///
  /// (Note: this method will execute additional queries to resolve table names the first time a table is encountered. These table names are cached per instance of this type.)
  ///
  /// Each row map contains key-value pairs for every table in the query. The value is a [Map] that contains
  /// key-value pairs for each column from that table. For example, consider
  /// the following query:
  ///
  ///         SELECT employee.id, employee.name FROM employee;
  ///
  /// This method would return the following structure:
  ///
  ///         [
  ///           {"employee" : {"name": "Bob", "id": 1}}
  ///         ]
  ///
  /// The purpose of this nested structure is to disambiguate columns that have the same name in different tables. For example, consider a query with a SQL JOIN:
  ///
  ///         SELECT employee.id, employee.name, company.name FROM employee LEFT OUTER JOIN company ON employee.company_id=company.id;
  ///
  /// Each returned [Map] would contain `employee` and `company` keys. The `name` key would be present in both inner maps.
  ///
  ///       [
  ///         {
  ///           "employee": {"name": "Bob", "id": 1},
  ///           "company: {"name": "stable|kernel"}
  ///         }
  ///       ]
  Future<List<Map<String, Map<String, dynamic>>>> mappedResultsQuery(
      String fmtString,
      {Map<String, dynamic>? substitutionValues,
      bool? allowReuse,
      int? timeoutInSeconds});
}

/// A description of a column.
class ColumnDescription {
  /// The name of the column returned by the query.
  final String columnName;

  /// The resolved name of the referenced table.
  final String tableName;

  /// The Object Identifier of the column type.
  final int typeId;

  ColumnDescription({
    required this.typeId,
    required this.tableName,
    required this.columnName,
  });
}

/// A single row of a query result.
///
/// Column values can be accessed through the `[]` operator.
abstract class PostgreSQLResultRow implements List {
  List<ColumnDescription> get columnDescriptions;

  /// Returns a two-level map that on the first level contains the resolved
  /// table name, and on the second level the column name (or its alias).
  Map<String, Map<String, dynamic>> toTableColumnMap();

  /// Returns a single-level map that maps the column name (or its alias) to the
  /// value returned on that position.
  Map<String, dynamic> toColumnMap();
}

/// The query result.
///
/// Rows can be accessed through the `[]` operator.
abstract class PostgreSQLResult implements List<PostgreSQLResultRow> {
  /// How many rows did this query affect?
  int get affectedRowCount;
  List<ColumnDescription> get columnDescriptions;
}
