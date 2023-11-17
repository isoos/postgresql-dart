// ignore_for_file: deprecated_member_use_from_same_package

part of 'connection.dart';

/// Represents a rollback from a transaction.
///
/// If a transaction is cancelled using [PostgreSQLExecutionContext.cancelTransaction], the value of the [Future]
/// returned from [PostgreSQLConnection.transaction] will be an instance of this type. [reason] will be the [String]
/// value of the optional argument to [PostgreSQLExecutionContext.cancelTransaction].
@Deprecated('Do not use v2 API, will be removed in next release.')
class PostgreSQLRollback {
  @internal
  PostgreSQLRollback(this.reason);

  /// The reason the transaction was cancelled.
  final String reason;

  @override
  String toString() => 'PostgreSQLRollback: $reason';
}
