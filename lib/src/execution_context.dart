import 'dart:async';
import 'query.dart';
import 'types.dart';
import 'substituter.dart';
import 'connection.dart';

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
  /// function to add parameters to a query string. This method inserts a parameter name and the appropriate ':type' string for a [PostgreSQLDataType].
  ///
  /// If successful, the returned [Future] completes with a [List] of rows. Each is row is represented by a [List] of column values for that row that were returned by the query.
  ///
  /// By default, instances of this class will reuse queries. This allows significantly more efficient transport to and from the database. You do not have to do
  /// anything to opt in to this behavior, this connection will track the necessary information required to reuse queries without intervention. (The [fmtString] is
  /// the unique identifier to look up reuse information.) You can disable reuse by passing false for [allowReuse].
  Future<List<List<dynamic>>> query(String fmtString,
    {Map<String, dynamic> substitutionValues: null, bool allowReuse: true, int timeoutInSeconds});

  /// Executes a query on this context.
  ///
  /// This method sends a SQL string to the database this instance is connected to. Parameters can be provided in [fmtString], see [query] for more details.
  ///
  /// This method returns the number of rows affected and no additional information. This method uses the least efficient and less secure command
  /// for executing queries in the PostgreSQL protocol; [query] is preferred for queries that will be executed more than once, will contain user input,
  /// or return rows.
  Future<int> execute(String fmtString, {Map<String, dynamic> substitutionValues: null, int timeoutInSeconds});

  /// Cancels a transaction on this context.
  ///
  /// If this context is an instance of [PostgreSQLConnection], this method has no effect. If the context is a transaction context (passed as the argument
  /// to [PostgreSQLConnection.transaction]), this will rollback the transaction.
  void cancelTransaction({String reason: null});

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
  Future<List<Map<String, Map<String, dynamic>>>> mappedResultsQuery(String fmtString,
    {Map<String, dynamic> substitutionValues: null, bool allowReuse: true, int timeoutInSeconds});
}