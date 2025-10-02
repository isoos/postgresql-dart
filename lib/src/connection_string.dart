import 'dart:convert';
import 'dart:io';

import '../postgres.dart';

({
  Endpoint endpoint,
  // standard parameters
  String? applicationName,
  Duration? connectTimeout,
  Encoding? encoding,
  ReplicationMode? replicationMode,
  SecurityContext? securityContext,
  SslMode? sslMode,
  // non-standard parameters
  Duration? queryTimeout,
  // pool parameters
  Duration? maxConnectionAge,
  int? maxConnectionCount,
  Duration? maxSessionUse,
  int? maxQueryCount,
})
parseConnectionString(
  String connectionString, {
  bool enablePoolSettings = false,
}) {
  final uri = Uri.parse(connectionString);

  if (uri.scheme != 'postgresql' && uri.scheme != 'postgres') {
    throw ArgumentError(
      'Invalid connection string scheme: ${uri.scheme}. Expected "postgresql" or "postgres".',
    );
  }

  final host = uri.host.isEmpty ? 'localhost' : uri.host;
  final port = uri.port == 0 ? 5432 : uri.port;
  final database = uri.pathSegments.firstOrNull ?? 'postgres';
  final username = uri.userInfo.isEmpty ? null : _parseUsername(uri.userInfo);
  final password = uri.userInfo.isEmpty ? null : _parsePassword(uri.userInfo);

  final validParams = {
    // Note: parameters here should be matched to https://www.postgresql.org/docs/current/libpq-connect.html
    'application_name',
    'client_encoding',
    'connect_timeout',
    'replication',
    'sslcert',
    'sslkey',
    'sslmode',
    'sslrootcert',
    // Note: some parameters are not part of the libpq-connect above
    'query_timeout',
    // Note: parameters here are only for pool-settings
    if (enablePoolSettings) ...[
      'max_connection_age',
      'max_connection_count',
      'max_session_use',
      'max_query_count',
    ],
  };

  final params = uri.queryParameters;
  for (final key in params.keys) {
    if (!validParams.contains(key)) {
      throw ArgumentError('Unrecognized connection parameter: $key');
    }
  }

  SslMode? sslMode;
  if (params.containsKey('sslmode')) {
    switch (params['sslmode']) {
      case 'disable':
        sslMode = SslMode.disable;
        break;
      case 'require':
        sslMode = SslMode.require;
        break;
      case 'verify-ca':
      case 'verify-full':
        sslMode = SslMode.verifyFull;
        break;
      default:
        throw ArgumentError(
          'Invalid sslmode value: ${params['sslmode']}. Expected: disable, require, verify-ca, verify-full',
        );
    }
  }

  SecurityContext? securityContext;
  if (params.containsKey('sslcert') ||
      params.containsKey('sslkey') ||
      params.containsKey('sslrootcert')) {
    try {
      securityContext = _createSecurityContext(
        certPath: params['sslcert'],
        keyPath: params['sslkey'],
        caPath: params['sslrootcert'],
      );
    } catch (e) {
      // re-throw with more context about connection string parsing
      throw ArgumentError('SSL configuration error in connection string: $e');
    }
  }

  Duration? connectTimeout;
  if (params.containsKey('connect_timeout')) {
    final timeoutSeconds = int.tryParse(params['connect_timeout']!);
    if (timeoutSeconds == null || timeoutSeconds <= 0) {
      throw ArgumentError(
        'Invalid connect_timeout value: ${params['connect_timeout']}. Expected positive integer.',
      );
    }
    connectTimeout = Duration(seconds: timeoutSeconds);
  }

  final applicationName = params['application_name'];

  Encoding? encoding;
  if (params.containsKey('client_encoding')) {
    switch (params['client_encoding']?.toUpperCase()) {
      case 'UTF8':
      case 'UTF-8':
        encoding = utf8;
        break;
      case 'LATIN1':
      case 'ISO-8859-1':
        encoding = latin1;
        break;
      default:
        throw ArgumentError(
          'Unsupported client_encoding: ${params['client_encoding']}. Supported: UTF8, LATIN1',
        );
    }
  }

  ReplicationMode? replicationMode;
  if (params.containsKey('replication')) {
    switch (params['replication']) {
      case 'database':
        replicationMode = ReplicationMode.logical;
        break;
      case 'true':
      case 'physical':
        replicationMode = ReplicationMode.physical;
        break;
      case 'false':
      case 'no_select':
        replicationMode = ReplicationMode.none;
        break;
      default:
        throw ArgumentError(
          'Invalid replication value: ${params['replication']}. Expected: database, true, physical, false, no_select',
        );
    }
  }

  Duration? queryTimeout;
  if (params.containsKey('query_timeout')) {
    final timeoutSeconds = int.tryParse(params['query_timeout']!);
    if (timeoutSeconds == null || timeoutSeconds <= 0) {
      throw ArgumentError(
        'Invalid query_timeout value: ${params['query_timeout']}. Expected positive integer.',
      );
    }
    queryTimeout = Duration(seconds: timeoutSeconds);
  }

  Duration? maxConnectionAge;
  if (enablePoolSettings && params.containsKey('max_connection_age')) {
    final ageSeconds = int.tryParse(params['max_connection_age']!);
    if (ageSeconds == null || ageSeconds <= 0) {
      throw ArgumentError(
        'Invalid max_connection_age value: ${params['max_connection_age']}. Expected positive integer.',
      );
    }
    maxConnectionAge = Duration(seconds: ageSeconds);
  }

  int? maxConnectionCount;
  if (enablePoolSettings && params.containsKey('max_connection_count')) {
    final count = int.tryParse(params['max_connection_count']!);
    if (count == null || count <= 0) {
      throw ArgumentError(
        'Invalid max_connection_count value: ${params['max_connection_count']}. Expected positive integer.',
      );
    }
    maxConnectionCount = count;
  }

  Duration? maxSessionUse;
  if (enablePoolSettings && params.containsKey('max_session_use')) {
    final sessionSeconds = int.tryParse(params['max_session_use']!);
    if (sessionSeconds == null || sessionSeconds <= 0) {
      throw ArgumentError(
        'Invalid max_session_use value: ${params['max_session_use']}. Expected positive integer.',
      );
    }
    maxSessionUse = Duration(seconds: sessionSeconds);
  }

  int? maxQueryCount;
  if (enablePoolSettings && params.containsKey('max_query_count')) {
    final count = int.tryParse(params['max_query_count']!);
    if (count == null || count <= 0) {
      throw ArgumentError(
        'Invalid max_query_count value: ${params['max_query_count']}. Expected positive integer.',
      );
    }
    maxQueryCount = count;
  }

  final endpoint = Endpoint(
    host: host,
    port: port,
    database: database,
    username: username,
    password: password,
  );

  return (
    endpoint: endpoint,
    sslMode: sslMode,
    securityContext: securityContext,
    connectTimeout: connectTimeout,
    applicationName: applicationName,
    encoding: encoding,
    replicationMode: replicationMode,
    queryTimeout: queryTimeout,
    maxConnectionAge: maxConnectionAge,
    maxConnectionCount: maxConnectionCount,
    maxSessionUse: maxSessionUse,
    maxQueryCount: maxQueryCount,
  );
}

String? _parseUsername(String userInfo) {
  final colonIndex = userInfo.indexOf(':');
  if (colonIndex == -1) {
    return Uri.decodeComponent(userInfo);
  }
  return Uri.decodeComponent(userInfo.substring(0, colonIndex));
}

String? _parsePassword(String userInfo) {
  final colonIndex = userInfo.indexOf(':');
  if (colonIndex == -1) {
    return null;
  }
  return Uri.decodeComponent(userInfo.substring(colonIndex + 1));
}

SecurityContext _createSecurityContext({
  String? certPath,
  String? keyPath,
  String? caPath,
}) {
  final context = SecurityContext();

  if (certPath != null) {
    try {
      context.useCertificateChain(certPath);
    } catch (e) {
      throw ArgumentError('Failed to load SSL certificate from $certPath: $e');
    }
  }

  if (keyPath != null) {
    try {
      context.usePrivateKey(keyPath);
    } catch (e) {
      throw ArgumentError('Failed to load SSL private key from $keyPath: $e');
    }
  }

  if (caPath != null) {
    try {
      context.setTrustedCertificates(caPath);
    } catch (e) {
      throw ArgumentError(
        'Failed to load SSL CA certificates from $caPath: $e',
      );
    }
  }

  return context;
}
