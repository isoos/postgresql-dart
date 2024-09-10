/// Provides runtime information about the current connection.
class ConnectionInfo {
  /// The read-only, passive view of the Postgresql's runtime/session parameters.
  final ConnectionParametersView parameters;

  ConnectionInfo({
    Map<String, String>? parameters,
  }) : parameters = ConnectionParametersView(values: parameters);
}

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
/// This class holds the latest parameter values send by the server on a single connection.
/// The values are not queried or updated actively.
///
/// The available parameters may be discovered following the instructions on these URLs:
/// - https://www.postgresql.org/docs/current/sql-show.html
/// - https://www.postgresql.org/docs/current/runtime-config.html
/// - https://www.postgresql.org/docs/current/libpq-status.html#LIBPQ-PQPARAMETERSTATUS
class ConnectionParametersView {
  final _values = <String, String>{};

  ConnectionParametersView({
    Map<String, String>? values,
  }) {
    if (values != null) {
      _values.addAll(values);
    }
  }

  Iterable<String> get keys => _values.keys;
  String? operator [](String key) => _values[key];

  String? get applicationName => _values['application_name'];
  String? get clientEncoding => _values['client_encoding'];
  String? get dateStyle => _values['DateStyle'];
  String? get integerDatetimes => _values['integer_datetimes'];
  String? get serverEncoding => _values['server_encoding'];
  String? get serverVersion => _values['server_version'];
  String? get timeZone => _values['TimeZone'];
}

extension ConnectionInfoExt on ConnectionInfo {
  void setParameter(String name, String value) {
    parameters._values[name] = value;
  }
}
