import 'dart:async';

import 'package:meta/meta.dart';

import '../../postgres.dart';
import 'pool_impl.dart';

final class PoolSettings {
  final int? maxConnectionCount;

  const PoolSettings({
    this.maxConnectionCount,
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
    SessionSettings? sessionSettings,
    PoolSettings? poolSettings,
  }) =>
      PoolImplementation(
        selector,
        sessionSettings,
        poolSettings,
      );

  /// Creates a connection pool from a fixed list of endpoints.
  factory Pool.withEndpoints(
    List<Endpoint> endpoints, {
    SessionSettings? sessionSettings,
    PoolSettings? poolSettings,
  }) =>
      PoolImplementation(
        roundRobinSelector(endpoints),
        sessionSettings,
        poolSettings,
      );

  /// Acquires a connection from this pool, opening a new one if necessary, and
  /// calls [fn] with it.
  ///
  /// The connection must not be used after [fn] returns as it could be used by
  /// another [withConnection] call later.
  Future<R> withConnection<R>(
    Future<R> Function(Connection connection) fn, {
    SessionSettings? sessionSettings,
    L? locality,
  });

  @override
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    L? locality,
  });

  @override
  Future<R> runTx<R>(
    Future<R> Function(Session session) fn, {
    L? locality,
  });

  // TODO: decide whether PgSession.execute and prepare methods should also take locality parameter
}

typedef EndpointSelector<L> = FutureOr<EndpointSelectorResult> Function(
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

class EndpointSelectorResult {
  final Endpoint endpoint;
  // TODO: add optional SessionSettings + merge with defaults

  EndpointSelectorResult({
    required this.endpoint,
  });
}
