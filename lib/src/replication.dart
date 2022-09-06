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

/// The Logical Decoding Output Plugins For Streaming Replication
///
/// [pgoutput] is the standard logical decoding plugin that is built in
/// PostgreSQL since version 10.
///
/// [wal2json] is a popular output plugin for logical decoding. The extension
/// must be available on the database when using this output option. When using
/// [wal2json] plugin, the following are some limitations:
/// - the plug-in does not emit events for tables without primary keys
/// - the plug-in does not support special values (NaN or infinity) for floating
///   point types
///
/// For more info, see [wal2json repo][].
///
/// [wal2json repo]: https://github.com/eulerto/wal2json
enum LogicalDecodingPlugin {
  pgoutput,
  wal2json,
}

