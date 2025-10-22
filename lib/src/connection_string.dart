import 'dart:convert';
import 'dart:io';

import '../postgres.dart';

({
  List<Endpoint> endpoints,
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
  // Pre-process connection string to extract comma-separated hosts from authority
  final preProcessed = _preprocessConnectionString(connectionString);

  final uri = Uri.parse(preProcessed.uri);

  if (uri.scheme != 'postgresql' && uri.scheme != 'postgres') {
    throw ArgumentError(
      'Invalid connection string scheme: ${uri.scheme}. Expected "postgresql" or "postgres".',
    );
  }

  final params = uri.queryParameters;

  // Database: query parameter overrides path
  final database =
      params['database'] ?? uri.pathSegments.firstOrNull ?? 'postgres';

  // Username: 'user' or 'username' query parameter overrides userInfo
  final username =
      params['user'] ??
      params['username'] ??
      (uri.userInfo.isEmpty ? null : _parseUsername(uri.userInfo));

  // Password: query parameter overrides userInfo
  final password =
      params['password'] ??
      (uri.userInfo.isEmpty ? null : _parsePassword(uri.userInfo));

  // Parse hosts
  final hosts = <({String host, int port, bool isUnixSocket})>[];

  // Add hosts from authority (extracted during preprocessing)
  if (preProcessed.hosts.isNotEmpty) {
    hosts.addAll(preProcessed.hosts);
  } else if (uri.host.isNotEmpty) {
    // No comma-separated hosts, use standard URI host
    hosts.add((
      host: uri.host,
      port: uri.port == 0 ? 5432 : uri.port,
      isUnixSocket: false,
    ));
  }

  // Parse host query parameters
  final defaultPort = params['port'] != null
      ? int.tryParse(params['port']!) ?? 5432
      : 5432;

  if (uri.queryParametersAll.containsKey('host')) {
    final hostParams = uri.queryParametersAll['host'] ?? [];
    for (final hostParam in hostParams) {
      final parsed = _parseHostPort(hostParam, defaultPort: defaultPort);
      hosts.add(parsed);
    }
  }

  // Default to localhost if no hosts specified
  if (hosts.isEmpty) {
    hosts.add((host: 'localhost', port: defaultPort, isUnixSocket: false));
  }

  final validParams = {
    // Note: parameters here should be matched to https://www.postgresql.org/docs/current/libpq-connect.html
    'application_name',
    'client_encoding',
    'connect_timeout',
    'database',
    'host',
    'password',
    'port',
    'replication',
    'sslcert',
    'sslkey',
    'sslmode',
    'sslrootcert',
    'user',
    'username',
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

  final endpoints = hosts
      .map(
        (h) => Endpoint(
          host: h.host,
          port: h.port,
          database: database,
          username: username,
          password: password,
          isUnixSocket: h.isUnixSocket,
        ),
      )
      .toList();

  return (
    endpoints: endpoints,
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

({String host, int port, bool isUnixSocket}) _parseHostPort(
  String hostPort, {
  required int defaultPort,
}) {
  // Check if it's a Unix socket (contains '/')
  final isUnixSocket = hostPort.contains('/');

  String host;
  int port;

  if (isUnixSocket) {
    // Unix socket - don't parse for port (may have colons in filename)
    host = hostPort;
    port = defaultPort;
  } else {
    // Regular host - check for port after colon
    final colonIndex = hostPort.lastIndexOf(':');
    if (colonIndex != -1) {
      host = hostPort.substring(0, colonIndex);
      port = int.tryParse(hostPort.substring(colonIndex + 1)) ?? defaultPort;
    } else {
      host = hostPort;
      port = defaultPort;
    }
  }

  return (host: host, port: port, isUnixSocket: isUnixSocket);
}

({String uri, List<({String host, int port, bool isUnixSocket})> hosts})
_preprocessConnectionString(String connectionString) {
  // Extract scheme
  final schemeEnd = connectionString.indexOf('://');
  if (schemeEnd == -1) {
    return (uri: connectionString, hosts: []);
  }

  final scheme = connectionString.substring(0, schemeEnd + 3);
  final rest = connectionString.substring(schemeEnd + 3);

  // Find where authority ends (at '/', '?', or end of string)
  final pathStart = rest.indexOf('/');
  final queryStart = rest.indexOf('?');

  int authorityEnd;
  if (pathStart != -1 && queryStart != -1) {
    authorityEnd = pathStart < queryStart ? pathStart : queryStart;
  } else if (pathStart != -1) {
    authorityEnd = pathStart;
  } else if (queryStart != -1) {
    authorityEnd = queryStart;
  } else {
    authorityEnd = rest.length;
  }

  final authority = rest.substring(0, authorityEnd);
  final remainder = rest.substring(authorityEnd);

  // Check if authority contains comma-separated hosts
  if (!authority.contains(',')) {
    // No comma-separated hosts, return as-is
    return (uri: connectionString, hosts: []);
  }

  // Split authority into userinfo and hostlist
  final atIndex = authority.indexOf('@');
  final String userInfo;
  final String hostlist;

  if (atIndex != -1) {
    userInfo = authority.substring(0, atIndex + 1); // includes '@'
    hostlist = authority.substring(atIndex + 1);
  } else {
    userInfo = '';
    hostlist = authority;
  }

  // Parse comma-separated hosts
  final hostParts = hostlist.split(',');
  final hosts = <({String host, int port, bool isUnixSocket})>[];

  for (final hostPart in hostParts) {
    final parsed = _parseHostPort(hostPart.trim(), defaultPort: 5432);
    hosts.add(parsed);
  }

  // Rebuild URI with only the first host for Uri.parse to work
  final firstHost = hosts.isNotEmpty ? hostParts[0] : '';
  final modifiedUri = '$scheme$userInfo$firstHost$remainder';

  return (uri: modifiedUri, hosts: hosts);
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
