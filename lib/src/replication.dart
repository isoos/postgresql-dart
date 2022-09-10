// TODO: these types could move to a common "connection_config.dart" file

/// Streaming Replication Protocol Options
///
/// [physical] or [logical] are used to start the connection a streaming
/// replication mode.
///
/// See [Protocol Replication][] for more details.
///
/// [Protocol Replication]: https://www.postgresql.org/docs/current/protocol-replication.html
enum ReplicationMode {
  physical('true'),
  logical('database'),
  none('false');

  final String value;

  const ReplicationMode(this.value);
}