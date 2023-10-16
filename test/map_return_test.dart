import 'dart:mirrors';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('map return', (server) {
    late PostgreSQLConnection connection;
    setUp(() async {
      connection = await server.newPostgreSQLConnection();
      await connection.open();

      await connection.execute('''
        CREATE TEMPORARY TABLE t (id int primary key, name text)
    ''');

      await connection.execute('''
        CREATE TEMPORARY TABLE u (id int primary key, name text, t_id int references t (id))
    ''');

      await connection.execute("INSERT INTO t (id, name) VALUES (1, 'a')");
      await connection.execute("INSERT INTO t (id, name) VALUES (2, 'b')");
      await connection.execute("INSERT INTO t (id, name) VALUES (3, 'c')");
      await connection
          .execute("INSERT INTO u (id, name, t_id) VALUES (1, 'ua', 1)");
      await connection
          .execute("INSERT INTO u (id, name, t_id) VALUES (2, 'ub', 1)");
      await connection
          .execute("INSERT INTO u (id, name, t_id) VALUES (3, 'uc', 2)");
    });

    tearDown(() async {
      await connection.close();
    });

    test('Get row map without specifying columns', () async {
      final results = await connection
          .mappedResultsQuery('SELECT * from t ORDER BY id ASC');
      expect(results, [
        {
          't': {'id': 1, 'name': 'a'}
        },
        {
          't': {'id': 2, 'name': 'b'}
        },
        {
          't': {'id': 3, 'name': 'c'}
        },
      ]);
    });

    test('Get row map by with specified columns', () async {
      final results = await connection
          .mappedResultsQuery('SELECT name, id from t ORDER BY id ASC');
      expect(results, [
        {
          't': {'id': 1, 'name': 'a'}
        },
        {
          't': {'id': 2, 'name': 'b'}
        },
        {
          't': {'id': 3, 'name': 'c'}
        },
      ]);

      final nextResults = await connection
          .mappedResultsQuery('SELECT name from t ORDER BY name DESC');
      expect(nextResults, [
        {
          't': {'name': 'c'}
        },
        {
          't': {'name': 'b'}
        },
        {
          't': {'name': 'a'}
        },
      ]);
    });

    test('Get row with joined row', () async {
      final results = await connection.mappedResultsQuery(
          'SELECT t.name, t.id, u.id, u.name, u.t_id from t LEFT OUTER JOIN u ON t.id=u.t_id ORDER BY t.id ASC');
      expect(results, [
        {
          't': {'name': 'a', 'id': 1},
          'u': {'id': 1, 'name': 'ua', 't_id': 1}
        },
        {
          't': {'name': 'a', 'id': 1},
          'u': {'id': 2, 'name': 'ub', 't_id': 1}
        },
        {
          't': {'name': 'b', 'id': 2},
          'u': {'id': 3, 'name': 'uc', 't_id': 2}
        },
        {
          't': {'name': 'c', 'id': 3},
          'u': {'name': null, 'id': null, 't_id': null}
        }
      ]);
    });

    test('Table names get cached', () async {
      clearOidQueryCount(connection);
      expect(getOidQueryCount(connection), 0);

      await connection.mappedResultsQuery('SELECT id FROM t');
      expect(getOidQueryCount(connection), 1);

      await connection.mappedResultsQuery('SELECT id FROM t');
      expect(getOidQueryCount(connection), 1);

      await connection.mappedResultsQuery(
          'SELECT t.id, u.id FROM t LEFT OUTER JOIN u ON t.id=u.t_id');
      expect(getOidQueryCount(connection), 2);

      await connection.mappedResultsQuery('SELECT u.id FROM u');
      expect(getOidQueryCount(connection), 2);
    }, skip: server.skippedOnV3('oid cache is not implemented in v3'));

    test('Non-table mappedResultsQuery succeeds', () async {
      final result = await connection.mappedResultsQuery('SELECT 1');
      expect(result, [
        {
          '': {'?column?': 1}
        }
      ]);
    }, skip: server.skippedOnV3('mappedResultsQuery is a removed feature'));
  });
}

void clearOidQueryCount(PostgreSQLConnection connection) {
  final oidCacheMirror = reflect(connection)
      .type
      .declarations
      .values
      .firstWhere((DeclarationMirror dm) =>
          dm.simpleName.toString().contains('_oidCache'));
  // TODO(eseidel): Fix this by using @visibleForTesting instead of mirrors?
  // ignore: avoid_dynamic_calls
  reflect(connection).getField(oidCacheMirror.simpleName).reflectee.clear();
}

int getOidQueryCount(PostgreSQLConnection connection) {
  final oidCacheMirror = reflect(connection)
      .type
      .declarations
      .values
      .firstWhere((DeclarationMirror dm) =>
          dm.simpleName.toString().contains('_oidCache'));
  // TODO(eseidel): Fix this by using @visibleForTesting instead of mirrors?
  // ignore: avoid_dynamic_calls
  return reflect(connection)
      .getField(oidCacheMirror.simpleName)
      .reflectee
      .queryCount as int;
}
