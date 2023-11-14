part of 'connection.dart';

/// Represents a rollback from a transaction.
///
/// If a transaction is cancelled using [PostgreSQLExecutionContext.cancelTransaction], the value of the [Future]
/// returned from [PostgreSQLConnection.transaction] will be an instance of this type. [reason] will be the [String]
/// value of the optional argument to [PostgreSQLExecutionContext.cancelTransaction].
class PostgreSQLRollback {
  @internal
  PostgreSQLRollback(this.reason);

  /// The reason the transaction was cancelled.
  final String reason;

  @override
  String toString() => 'PostgreSQLRollback: $reason';
}
