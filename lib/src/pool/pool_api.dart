import 'dart:async';

import 'package:meta/meta.dart';

import '../../postgres.dart';
import 'pool_impl.dart';

class PoolSettings extends ConnectionSettings {
  /// The maximum number of concurrent sessions.
  final int? maxConnectionCount;

  /// The maximum duration a connection is kept open.
  /// New sessions won't be scheduled after this limit is reached.
  final Duration? maxConnectionAge;

  /// The maximum duration a connection is used by sessions.
  /// New sessions won't be scheduled after this limit is reached.
  final Duration? maxSessionUse;

  /// The maximum number of queries to be run on a connection.
  /// New sessions won't be scheduled after this limit is reached.
  ///
  /// NOTE: not yet implemented
  final int? maxQueryCount;

  const PoolSettings({
    this.maxConnectionCount,
    this.maxConnectionAge,
    this.maxSessionUse,
    this.maxQueryCount,
    super.applicationName,
    super.connectTimeout,
    super.sslMode,
    super.securityContext,
    super.encoding,
    super.timeZone,
    super.replicationMode,
    super.transformer,
    super.queryTimeout,
    super.queryMode,
    super.ignoreSuperfluousParameters,
    super.onOpen,
    super.typeRegistry,
  });
}

/// A connection pool that may select endpoints based on the requested locality
/// [L] of the data.
///
/// A data locality can be an arbitrary value that the pool's [EndpointSelector]
/// understands, and may return a connection based on, e.g:
/// - an action, which applies to different database or user,
/// - a tenant, which may be specified for multi-tenant applications,
/// - a table and key, which may be specified for distributed databases
///   (e.g. CockroachDB) for selecting the node that is the leader for the
///   specified data range.
/// - a primary/replica status, whic may be specified for cases where stale or
///   read-only data is acceptable
abstract class Pool<L> implements Session, SessionExecutor {
  factory Pool.withSelector(
    EndpointSelector<L> selector, {
    PoolSettings? settings,
  }) =>
      PoolImplementation(selector, settings);

  /// Creates a connection pool from a fixed list of endpoints.
  factory Pool.withEndpoints(
    List<Endpoint> endpoints, {
    PoolSettings? settings,
  }) =>
      PoolImplementation(roundRobinSelector(endpoints), settings);

  /// Acquires a connection from this pool, opening a new one if necessary, and
  /// calls [fn] with it.
  ///
  /// The connection must not be used after [fn] returns as it could be used by
  /// another [withConnection] call later.
  Future<R> withConnection<R>(
    Future<R> Function(Connection connection) fn, {
    ConnectionSettings? settings,
    L? locality,
  });

  @override
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    SessionSettings? settings,
    L? locality,
  });

  @override
  Future<R> runTx<R>(
    Future<R> Function(TxSession session) fn, {
    TransactionSettings? settings,
    L? locality,
  });

  // TODO: decide whether PgSession.execute and prepare methods should also take locality parameter
}

typedef EndpointSelector<L> = FutureOr<EndpointSelection> Function(
    EndpointSelectorContext<L> context);

final class EndpointSelectorContext<L> {
  final L? locality;
  // TODO: expose currently open/idle connections/endpoints
  // TODO: expose usage and latency information about endpoints

  @internal
  EndpointSelectorContext({
    required this.locality,
  });
}

class EndpointSelection {
  final Endpoint endpoint;
  // TODO: add optional SessionSettings + merge with defaults

  EndpointSelection({
    required this.endpoint,
  });
}
