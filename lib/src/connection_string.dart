import 'dart:convert';
import 'dart:io';

import '../postgres.dart';

({
  Endpoint endpoint,
  String? applicationName,
  Duration? connectTimeout,
  Encoding? encoding,
  ReplicationMode? replicationMode,
  SecurityContext? securityContext,
  SslMode? sslMode,
}) parseConnectionString(String connectionString) {
  final uri = Uri.parse(connectionString);

  if (uri.scheme != 'postgresql' && uri.scheme != 'postgres') {
    throw ArgumentError(
        'Invalid connection string scheme: ${uri.scheme}. Expected "postgresql" or "postgres".');
  }

  final host = uri.host.isEmpty ? 'localhost' : uri.host;
  final port = uri.port == 0 ? 5432 : uri.port;
  final database = uri.pathSegments.firstOrNull ?? 'postgres';
  final username = uri.userInfo.isEmpty ? null : _parseUsername(uri.userInfo);
  final password = uri.userInfo.isEmpty ? null : _parsePassword(uri.userInfo);

  final validParams = {
    'sslmode',
    'sslcert',
    'sslkey',
    'sslrootcert',
    'connect_timeout',
    'application_name',
    'client_encoding',
    'replication'
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
            'Invalid sslmode value: ${params['sslmode']}. Expected: disable, require, verify-ca, verify-full');
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
          'Invalid connect_timeout value: ${params['connect_timeout']}. Expected positive integer.');
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
            'Unsupported client_encoding: ${params['client_encoding']}. Supported: UTF8, LATIN1');
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
            'Invalid replication value: ${params['replication']}. Expected: database, true, physical, false, no_select');
    }
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
          'Failed to load SSL CA certificates from $caPath: $e');
    }
  }

  return context;
}
