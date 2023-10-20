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

abstract class Pool implements Session, SessionExecutor {
  factory Pool.withSelector(
    EndpointSelector selector, {
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
    Locality? locality,
  });

  @override
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    Locality? locality,
  });

  @override
  Future<R> runTx<R>(
    Future<R> Function(Session session) fn, {
    Locality? locality,
  });

  // TODO: decide on PgSession.execute and prepare methods, whether to extend those too.
}

/// A data locality request from the caller that may guide the [Pool] to select
/// the appropriate endpoint. For example:
/// - [action] may be specified for custom routing
/// - [tenant] may be specified for multi-tenant applications
/// - [table] and [key] may be specified for distributed databases (e.g. CockroachDB)
///   for selecting the node that is the leader for the specified data range.
/// - TBD: primary/replica status may be specified for cases where stale or
///   read-only data is acceptable
class Locality {
  // TODO/TBD: add primary/replica type selection, eg. acceptReadOnly or enum

  final String? action;
  final Object? tenant;
  final String? table;
  final Object? key;

  Locality({
    this.action,
    this.tenant,
    this.table,
    this.key,
  });
}

typedef EndpointSelector = FutureOr<EndpointSelectorResult> Function(
    EndpointSelectorContext context);

final class EndpointSelectorContext {
  final Locality? locality;
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
