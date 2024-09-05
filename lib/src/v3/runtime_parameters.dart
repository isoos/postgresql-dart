import 'dart:collection';

/// The read-only, passive view of the Postgresql's runtime/session parameters.
///
/// Postgresql server reports certain parameter values at opening a connection
/// or whenever their values change. Such parameters may include:
/// - `application_name`
/// - `server_version`
/// - `server_encoding`
/// - `client_encoding`
/// - `is_superuser`
/// - `session_authorization`
/// - `DateStyle`
/// - `TimeZone`
/// - `integer_datetimes`
///
/// This class holds the latest parameter values send by the server.
/// The values are not queried or updated actively.
///
/// The available parameters may be discovered following the instructions on these URLs:
/// - https://www.postgresql.org/docs/current/sql-show.html
/// - https://www.postgresql.org/docs/current/runtime-config.html
/// - https://www.postgresql.org/docs/current/libpq-status.html#LIBPQ-PQPARAMETERSTATUS
class RuntimeParameters {
  final _values = <String, String>{};

  RuntimeParameters({Map<String, String>? initialValues}) {
    if (initialValues != null) {
      _values.addAll(initialValues);
    }
  }

  /// The latest values of the runtime parameters. The map is read-only.
  late final latestValues = UnmodifiableMapView(_values);

  String? get applicationName => latestValues['application_name'];
  String? get clientEncoding => latestValues['client_encoding'];
  String? get dateStyle => latestValues['DateStyle'];
  String? get integerDatetimes => latestValues['integer_datetimes'];
  String? get serverEncoding => latestValues['server_encoding'];
  String? get serverVersion => latestValues['server_version'];
  String? get timeZone => latestValues['TimeZone'];
}

extension RuntimeParametersExt on RuntimeParameters {
  void setValue(String name, String value) {
    _values[name] = value;
  }
}
