import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:postgres/src/connection_string.dart';
import 'package:test/test.dart';

void main() {
  group('Connection String Parser', () {
    group('Basic parsing', () {
      test('minimal connection string', () {
        final result = parseConnectionString('postgresql://localhost/test');

        expect(result.endpoint.host, equals('localhost'));
        expect(result.endpoint.port, equals(5432));
        expect(result.endpoint.database, equals('test'));
        expect(result.endpoint.username, isNull);
        expect(result.endpoint.password, isNull);
        expect(result.applicationName, isNull);
        expect(result.connectTimeout, isNull);
        expect(result.encoding, isNull);
        expect(result.replicationMode, isNull);
        expect(result.securityContext, isNull);
        expect(result.sslMode, isNull);
      });

      test('full connection string with credentials', () {
        final result = parseConnectionString(
            'postgresql://user:password@host:9999/database');

        expect(result.endpoint.host, equals('host'));
        expect(result.endpoint.port, equals(9999));
        expect(result.endpoint.database, equals('database'));
        expect(result.endpoint.username, equals('user'));
        expect(result.endpoint.password, equals('password'));
      });

      test('default values when components missing', () {
        final result = parseConnectionString('postgresql:///');

        expect(result.endpoint.host, equals('localhost'));
        expect(result.endpoint.port, equals(5432));
        expect(result.endpoint.database, equals('postgres'));
      });

      test('URL encoded credentials', () {
        final result = parseConnectionString(
            'postgresql://user%40domain:p%40ssw%3Ard@host/db');

        expect(result.endpoint.username, equals('user@domain'));
        expect(result.endpoint.password, equals('p@ssw:rd'));
      });

      test('postgres scheme alias', () {
        final result = parseConnectionString('postgres://localhost/test');

        expect(result.endpoint.host, equals('localhost'));
        expect(result.endpoint.database, equals('test'));
      });
    });

    group('SSL parameters', () {
      test('sslmode disable', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?sslmode=disable');

        expect(result.sslMode, equals(SslMode.disable));
        expect(result.securityContext, isNull);
      });

      test('sslmode require', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?sslmode=require');

        expect(result.sslMode, equals(SslMode.require));
      });

      test('sslmode verify-ca', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?sslmode=verify-ca');

        expect(result.sslMode, equals(SslMode.verifyFull));
      });

      test('sslmode verify-full', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?sslmode=verify-full');

        expect(result.sslMode, equals(SslMode.verifyFull));
      });

      test('SSL certificate paths create SecurityContext', () {
        // This test will fail if certificate files don't exist, which is expected behavior
        expect(
          () => parseConnectionString(
              'postgresql://localhost/test?sslcert=/path/to/cert.pem&sslkey=/path/to/key.pem&sslrootcert=/path/to/ca.pem'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('SSL configuration error'),
          )),
        );
      });

      test('single SSL certificate parameter triggers SSL loading', () {
        expect(
          () => parseConnectionString(
              'postgresql://localhost/test?sslcert=/path/to/cert.pem'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('SSL configuration error'),
          )),
        );
      });
    });

    group('Timeout and application name', () {
      test('connect_timeout parameter', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?connect_timeout=30');

        expect(result.connectTimeout, equals(Duration(seconds: 30)));
      });

      test('application_name parameter', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?application_name=my_app');

        expect(result.applicationName, equals('my_app'));
      });

      test('URL encoded application name', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?application_name=my%20app');

        expect(result.applicationName, equals('my app'));
      });

      test('combined timeout and application name', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?connect_timeout=45&application_name=test_suite');

        expect(result.connectTimeout, equals(Duration(seconds: 45)));
        expect(result.applicationName, equals('test_suite'));
      });
    });

    group('Encoding and replication', () {
      test('client_encoding UTF8', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?client_encoding=UTF8');

        expect(result.encoding, equals(utf8));
      });

      test('client_encoding UTF-8 (with dash)', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?client_encoding=UTF-8');

        expect(result.encoding, equals(utf8));
      });

      test('client_encoding LATIN1', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?client_encoding=LATIN1');

        expect(result.encoding, equals(latin1));
      });

      test('client_encoding ISO-8859-1', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?client_encoding=ISO-8859-1');

        expect(result.encoding, equals(latin1));
      });

      test('replication database (logical)', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?replication=database');

        expect(
            result.replicationMode, equals(ReplicationMode.logical));
      });

      test('replication true (physical)', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?replication=true');

        expect(
            result.replicationMode, equals(ReplicationMode.physical));
      });

      test('replication physical', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?replication=physical');

        expect(
            result.replicationMode, equals(ReplicationMode.physical));
      });

      test('replication false (none)', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?replication=false');

        expect(result.replicationMode, equals(ReplicationMode.none));
      });

      test('replication no_select (none)', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?replication=no_select');

        expect(result.replicationMode, equals(ReplicationMode.none));
      });
    });

    group('Error handling', () {
      test('invalid scheme throws ArgumentError', () {
        expect(
          () => parseConnectionString('mysql://localhost/test'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid connection string scheme: mysql'),
          )),
        );
      });

      test('unrecognized parameter throws ArgumentError', () {
        expect(
          () => parseConnectionString(
              'postgresql://localhost/test?invalid_param=value'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unrecognized connection parameter: invalid_param'),
          )),
        );
      });

      test('invalid sslmode throws ArgumentError', () {
        expect(
          () => parseConnectionString(
              'postgresql://localhost/test?sslmode=invalid'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid sslmode value: invalid'),
          )),
        );
      });

      test('invalid connect_timeout throws ArgumentError', () {
        expect(
          () => parseConnectionString(
              'postgresql://localhost/test?connect_timeout=not_a_number'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid connect_timeout value: not_a_number'),
          )),
        );
      });

      test('zero connect_timeout throws ArgumentError', () {
        expect(
          () => parseConnectionString(
              'postgresql://localhost/test?connect_timeout=0'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid connect_timeout value: 0'),
          )),
        );
      });

      test('negative connect_timeout throws ArgumentError', () {
        expect(
          () => parseConnectionString(
              'postgresql://localhost/test?connect_timeout=-5'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid connect_timeout value: -5'),
          )),
        );
      });

      test('unsupported client_encoding throws ArgumentError', () {
        expect(
          () => parseConnectionString(
              'postgresql://localhost/test?client_encoding=ASCII'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unsupported client_encoding: ASCII'),
          )),
        );
      });

      test('invalid replication value throws ArgumentError', () {
        expect(
          () => parseConnectionString(
              'postgresql://localhost/test?replication=invalid'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid replication value: invalid'),
          )),
        );
      });
    });

    group('Complex scenarios', () {
      test('multiple parameters combined', () {
        final result =
            parseConnectionString('postgresql://user:pass@host:5433/mydb?'
                'sslmode=require&'
                'connect_timeout=60&'
                'application_name=integration_test&'
                'client_encoding=UTF8&'
                'replication=database');

        expect(result.endpoint.host, equals('host'));
        expect(result.endpoint.port, equals(5433));
        expect(result.endpoint.database, equals('mydb'));
        expect(result.endpoint.username, equals('user'));
        expect(result.endpoint.password, equals('pass'));

        expect(result.sslMode, equals(SslMode.require));
        expect(result.connectTimeout, equals(Duration(seconds: 60)));
        expect(result.applicationName, equals('integration_test'));
        expect(result.encoding, equals(utf8));
        expect(
            result.replicationMode, equals(ReplicationMode.logical));
      });

      test('empty parameter values are handled', () {
        final result = parseConnectionString(
            'postgresql://localhost/test?application_name=');

        expect(result.applicationName, equals(''));
      });
    });
  });
}
