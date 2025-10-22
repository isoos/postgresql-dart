import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:postgres/src/connection_string.dart';
import 'package:test/test.dart';

void main() {
  group('Connection String Parser', () {
    group('Basic parsing', () {
      test('minimal connection string', () {
        final result = parseConnectionString('postgresql://localhost/test');

        final endpoint = result.endpoints.single;
        expect(endpoint.host, equals('localhost'));
        expect(endpoint.port, equals(5432));
        expect(endpoint.database, equals('test'));
        expect(endpoint.username, isNull);
        expect(endpoint.password, isNull);
        expect(result.applicationName, isNull);
        expect(result.connectTimeout, isNull);
        expect(result.encoding, isNull);
        expect(result.replicationMode, isNull);
        expect(result.securityContext, isNull);
        expect(result.sslMode, isNull);
      });

      test('full connection string with credentials', () {
        final result = parseConnectionString(
          'postgresql://user:password@host:9999/database',
        );

        final endpoint = result.endpoints.single;
        expect(endpoint.host, equals('host'));
        expect(endpoint.port, equals(9999));
        expect(endpoint.database, equals('database'));
        expect(endpoint.username, equals('user'));
        expect(endpoint.password, equals('password'));
      });

      test('default values when components missing', () {
        final result = parseConnectionString('postgresql:///');

        final endpoint = result.endpoints.single;
        expect(endpoint.host, equals('localhost'));
        expect(endpoint.port, equals(5432));
        expect(endpoint.database, equals('postgres'));
      });

      test('URL encoded credentials', () {
        final result = parseConnectionString(
          'postgresql://user%40domain:p%40ssw%3Ard@host/db',
        );

        final endpoint = result.endpoints.single;
        expect(endpoint.username, equals('user@domain'));
        expect(endpoint.password, equals('p@ssw:rd'));
      });

      test('postgres scheme alias', () {
        final result = parseConnectionString('postgres://localhost/test');

        final endpoint = result.endpoints.single;
        expect(endpoint.host, equals('localhost'));
        expect(endpoint.database, equals('test'));
      });
    });

    group('SSL parameters', () {
      test('sslmode disable', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?sslmode=disable',
        );

        expect(result.sslMode, equals(SslMode.disable));
        expect(result.securityContext, isNull);
      });

      test('sslmode require', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?sslmode=require',
        );

        expect(result.sslMode, equals(SslMode.require));
      });

      test('sslmode verify-ca', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?sslmode=verify-ca',
        );

        expect(result.sslMode, equals(SslMode.verifyFull));
      });

      test('sslmode verify-full', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?sslmode=verify-full',
        );

        expect(result.sslMode, equals(SslMode.verifyFull));
      });

      test('SSL certificate paths create SecurityContext', () {
        // This test will fail if certificate files don't exist, which is expected behavior
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?sslcert=/path/to/cert.pem&sslkey=/path/to/key.pem&sslrootcert=/path/to/ca.pem',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('SSL configuration error'),
            ),
          ),
        );
      });

      test('single SSL certificate parameter triggers SSL loading', () {
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?sslcert=/path/to/cert.pem',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('SSL configuration error'),
            ),
          ),
        );
      });
    });

    group('Timeout and application name', () {
      test('connect_timeout parameter', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?connect_timeout=30',
        );

        expect(result.connectTimeout, equals(Duration(seconds: 30)));
      });

      test('application_name parameter', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?application_name=my_app',
        );

        expect(result.applicationName, equals('my_app'));
      });

      test('URL encoded application name', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?application_name=my%20app',
        );

        expect(result.applicationName, equals('my app'));
      });

      test('combined timeout and application name', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?connect_timeout=45&application_name=test_suite',
        );

        expect(result.connectTimeout, equals(Duration(seconds: 45)));
        expect(result.applicationName, equals('test_suite'));
      });
    });

    group('Encoding and replication', () {
      test('client_encoding UTF8', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?client_encoding=UTF8',
        );

        expect(result.encoding, equals(utf8));
      });

      test('client_encoding UTF-8 (with dash)', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?client_encoding=UTF-8',
        );

        expect(result.encoding, equals(utf8));
      });

      test('client_encoding LATIN1', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?client_encoding=LATIN1',
        );

        expect(result.encoding, equals(latin1));
      });

      test('client_encoding ISO-8859-1', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?client_encoding=ISO-8859-1',
        );

        expect(result.encoding, equals(latin1));
      });

      test('replication database (logical)', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?replication=database',
        );

        expect(result.replicationMode, equals(ReplicationMode.logical));
      });

      test('replication true (physical)', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?replication=true',
        );

        expect(result.replicationMode, equals(ReplicationMode.physical));
      });

      test('replication physical', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?replication=physical',
        );

        expect(result.replicationMode, equals(ReplicationMode.physical));
      });

      test('replication false (none)', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?replication=false',
        );

        expect(result.replicationMode, equals(ReplicationMode.none));
      });

      test('replication no_select (none)', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?replication=no_select',
        );

        expect(result.replicationMode, equals(ReplicationMode.none));
      });
    });

    group('Error handling', () {
      test('invalid scheme throws ArgumentError', () {
        expect(
          () => parseConnectionString('mysql://localhost/test'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid connection string scheme: mysql'),
            ),
          ),
        );
      });

      test('unrecognized parameter throws ArgumentError', () {
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?invalid_param=value',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Unrecognized connection parameter: invalid_param'),
            ),
          ),
        );
      });

      test('invalid sslmode throws ArgumentError', () {
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?sslmode=invalid',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid sslmode value: invalid'),
            ),
          ),
        );
      });

      test('invalid connect_timeout throws ArgumentError', () {
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?connect_timeout=not_a_number',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid connect_timeout value: not_a_number'),
            ),
          ),
        );
      });

      test('zero connect_timeout throws ArgumentError', () {
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?connect_timeout=0',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid connect_timeout value: 0'),
            ),
          ),
        );
      });

      test('negative connect_timeout throws ArgumentError', () {
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?connect_timeout=-5',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid connect_timeout value: -5'),
            ),
          ),
        );
      });

      test('unsupported client_encoding throws ArgumentError', () {
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?client_encoding=ASCII',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Unsupported client_encoding: ASCII'),
            ),
          ),
        );
      });

      test('invalid replication value throws ArgumentError', () {
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?replication=invalid',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid replication value: invalid'),
            ),
          ),
        );
      });
    });

    group('Query parameter overrides', () {
      test('user, password, database, and port as query parameters', () {
        final result = parseConnectionString(
          'postgresql:///?user=queryuser&password=querypass&database=querydb&port=9876',
        );

        final endpoint = result.endpoints.single;
        expect(endpoint.host, equals('localhost'));
        expect(endpoint.port, equals(9876));
        expect(endpoint.database, equals('querydb'));
        expect(endpoint.username, equals('queryuser'));
        expect(endpoint.password, equals('querypass'));
      });
    });

    group('Complex scenarios', () {
      test('multiple parameters combined', () {
        final result = parseConnectionString(
          'postgresql://user:pass@host:5433/mydb?'
          'sslmode=require&'
          'connect_timeout=60&'
          'application_name=integration_test&'
          'client_encoding=UTF8&'
          'replication=database',
        );

        final endpoint = result.endpoints.single;
        expect(endpoint.host, equals('host'));
        expect(endpoint.port, equals(5433));
        expect(endpoint.database, equals('mydb'));
        expect(endpoint.username, equals('user'));
        expect(endpoint.password, equals('pass'));

        expect(result.sslMode, equals(SslMode.require));
        expect(result.connectTimeout, equals(Duration(seconds: 60)));
        expect(result.applicationName, equals('integration_test'));
        expect(result.encoding, equals(utf8));
        expect(result.replicationMode, equals(ReplicationMode.logical));
      });

      test('empty parameter values are handled', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?application_name=',
        );

        expect(result.applicationName, equals(''));
      });
    });

    group('Multiple hosts', () {
      test('comma-separated hosts in URI', () {
        final result = parseConnectionString(
          'postgresql://host1:5433,host2:5434,host3/mydb',
        );

        expect(result.endpoints, hasLength(3));

        expect(result.endpoints[0].host, equals('host1'));
        expect(result.endpoints[0].port, equals(5433));
        expect(result.endpoints[0].database, equals('mydb'));
        expect(result.endpoints[0].isUnixSocket, isFalse);

        expect(result.endpoints[1].host, equals('host2'));
        expect(result.endpoints[1].port, equals(5434));
        expect(result.endpoints[1].database, equals('mydb'));
        expect(result.endpoints[1].isUnixSocket, isFalse);

        expect(result.endpoints[2].host, equals('host3'));
        expect(result.endpoints[2].port, equals(5432)); // default port
        expect(result.endpoints[2].database, equals('mydb'));
        expect(result.endpoints[2].isUnixSocket, isFalse);
      });

      test('multiple host query parameters', () {
        final result = parseConnectionString(
          'postgresql:///mydb?host=host1:5433&host=host2:5434&host=host3',
        );

        expect(result.endpoints, hasLength(3));

        expect(result.endpoints[0].host, equals('host1'));
        expect(result.endpoints[0].port, equals(5433));
        expect(result.endpoints[0].database, equals('mydb'));
        expect(result.endpoints[0].isUnixSocket, isFalse);

        expect(result.endpoints[1].host, equals('host2'));
        expect(result.endpoints[1].port, equals(5434));
        expect(result.endpoints[1].database, equals('mydb'));
        expect(result.endpoints[1].isUnixSocket, isFalse);

        expect(result.endpoints[2].host, equals('host3'));
        expect(result.endpoints[2].port, equals(5432)); // default port
        expect(result.endpoints[2].database, equals('mydb'));
        expect(result.endpoints[2].isUnixSocket, isFalse);
      });

      test('Unix socket as query parameter host', () {
        final result = parseConnectionString(
          'postgresql:///mydb?host=/var/run/postgresql',
        );

        expect(result.endpoints, hasLength(1));

        expect(result.endpoints[0].host, equals('/var/run/postgresql'));
        expect(result.endpoints[0].port, equals(5432)); // default port
        expect(result.endpoints[0].database, equals('mydb'));
        expect(result.endpoints[0].isUnixSocket, isTrue);
      });

      test('Unix socket with colon in path', () {
        final result = parseConnectionString(
          'postgresql:///mydb?host=/var/run:with:colons/postgresql',
        );

        expect(result.endpoints, hasLength(1));

        expect(
          result.endpoints[0].host,
          equals('/var/run:with:colons/postgresql'),
        );
        expect(
          result.endpoints[0].port,
          equals(5432),
        ); // should not parse colons as port
        expect(result.endpoints[0].database, equals('mydb'));
        expect(result.endpoints[0].isUnixSocket, isTrue);
      });
    });

    group('Query timeout and pool parameters', () {
      test('query_timeout parameter', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?query_timeout=45',
        );
        expect(result.queryTimeout, equals(Duration(seconds: 45)));
      });

      test('query_timeout validation', () {
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?query_timeout=invalid',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid query_timeout'),
            ),
          ),
        );
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?query_timeout=0',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid query_timeout'),
            ),
          ),
        );
      });

      test('pool parameters with enablePoolSettings', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?max_connection_age=3600&max_connection_count=10&max_session_use=7200&max_query_count=1000',
          enablePoolSettings: true,
        );
        expect(result.maxConnectionAge, equals(Duration(seconds: 3600)));
        expect(result.maxConnectionCount, equals(10));
        expect(result.maxSessionUse, equals(Duration(seconds: 7200)));
        expect(result.maxQueryCount, equals(1000));
      });

      test('pool parameters rejected without enablePoolSettings', () {
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?max_connection_age=3600',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Unrecognized connection parameter'),
            ),
          ),
        );
      });

      test('pool parameter validation', () {
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?max_connection_age=0',
            enablePoolSettings: true,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid max_connection_age'),
            ),
          ),
        );
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?max_connection_count=invalid',
            enablePoolSettings: true,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid max_connection_count'),
            ),
          ),
        );
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?max_session_use=-5',
            enablePoolSettings: true,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid max_session_use'),
            ),
          ),
        );
        expect(
          () => parseConnectionString(
            'postgresql://localhost/test?max_query_count=0',
            enablePoolSettings: true,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid max_query_count'),
            ),
          ),
        );
      });

      test('all timeout and pool parameters combined', () {
        final result = parseConnectionString(
          'postgresql://localhost/test?query_timeout=30&max_connection_age=3600&max_connection_count=20&max_session_use=7200&max_query_count=500',
          enablePoolSettings: true,
        );
        expect(result.queryTimeout, equals(Duration(seconds: 30)));
        expect(result.maxConnectionAge, equals(Duration(seconds: 3600)));
        expect(result.maxConnectionCount, equals(20));
        expect(result.maxSessionUse, equals(Duration(seconds: 7200)));
        expect(result.maxQueryCount, equals(500));
      });
    });
  });
}
