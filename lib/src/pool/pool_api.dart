import '../../postgres.dart';
import 'pool_impl.dart';

final class PoolSettings {
  final int? maxConnectionCount;

  const PoolSettings({
    this.maxConnectionCount,
  });
}

abstract class Pool implements PgSession, PgSessionExecutor {
  factory Pool(
    List<PgEndpoint> endpoints, {
    PgSessionSettings? sessionSettings,
    PoolSettings? poolSettings,
  }) =>
      PoolImplementation(endpoints, sessionSettings, poolSettings);

  /// Acquires a connection from this pool, opening a new one if necessary, and
  /// calls [fn] with it.
  ///
  /// The connection must not be used after [fn] returns as it could be used by
  /// another [withConnection] call later.
  Future<R> withConnection<R>(
    Future<R> Function(PgConnection connection) fn, {
    PgSessionSettings? sessionSettings,
  });
}
