import 'dart:async';

import 'package:postgres/messages.dart';
import 'package:postgres/postgres.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'docker.dart';

final _tempTableQuery = '''
create table if not exists temp (
    id int GENERATED ALWAYS AS IDENTITY, 
    value text,
    PRIMARY KEY (id)
    );
''';

const String _host = 'localhost';
const int _port = 5432;
const String _username = 'dart';
const String _password = 'dart';
const String _database = 'dart_test';

// NOTES:
//
// - Two PostgreSQL connections are needed for testing replication.
//    - One for listening to streaming replications (connection will be locked).
//    - The other one to modify the database (e.g. insert, delete, update, truncate)
//
// - TODO: There's no tests for ReplicationMode.wal2json as the container needs
//         to have wal2json plugin installed. Once that's taken care of, tests
//         can be added.
void main() {
  usePostgresDocker();

  group('test logical replication with pgoutput', () {
    final logicalDecodingPlugin = LogicalDecodingPlugin.pgoutput;
    final replicationMode = ReplicationMode.logical;
    // use this for listening to messages
    var conn = PostgreSQLConnection(
      _host,
      _port,
      _database,
      username: _username,
      password: _password,
      replicationMode: replicationMode,
      logicalDecodingPlugin: logicalDecodingPlugin,
    );

    // use this for sending queries
    final conn2 = PostgreSQLConnection(
      _host,
      _port,
      _database,
      username: _username,
      password: _password,
    );

    setUpAll(() async {
      await conn.open();

      // Setup the database for replication
      await conn.execute('ALTER SYSTEM SET wal_level = logical;');
      await conn.execute('ALTER SYSTEM SET max_replication_slots = 5;');
      await conn.execute('ALTER SYSTEM SET max_wal_senders=5;');

      /// 'ALTER SYSTEM' statement requires restarting the database
      /// An easy way is to restart the docker container
      await conn.close();
      await restartContainer();

      // this is necessary as calling `conn.open()` won't work
      conn = PostgreSQLConnection(
        _host,
        _port,
        _database,
        username: _username,
        password: _password,
        replicationMode: replicationMode,
        logicalDecodingPlugin: logicalDecodingPlugin,
      );

      await Future.delayed(Duration(seconds: 1));
      await conn.open();
      await conn2.open();

      await conn.execute(_tempTableQuery);

      // create publication
      final publicationName = 'test_publication';
      await conn.execute('DROP PUBLICATION IF EXISTS $publicationName;');
      await conn.execute('CREATE PUBLICATION $publicationName FOR ALL TABLES;');

      final sysInfoRes =
          (await conn.simpleQuery('IDENTIFY_SYSTEM;')) as PostgreSQLResult;

      final xlogpos = sysInfoRes.first.toColumnMap()['xlogpos'] as String;

      // create replication slot
      final slotName = 'a_test_slot';
      await conn.execute('BEGIN READ ONLY ISOLATION LEVEL REPEATABLE READ');
      // `TEMPORARY` will remove the slot after the connection is closed/dropped
      await conn.execute(
        'CREATE_REPLICATION_SLOT $slotName TEMPORARY LOGICAL ${logicalDecodingPlugin.name} USE_SNAPSHOT',
      );
      await conn.execute('COMMIT');

      // start replication process
      var statement = 'START_REPLICATION SLOT $slotName LOGICAL $xlogpos ';
      switch (logicalDecodingPlugin) {
        case LogicalDecodingPlugin.pgoutput:
          statement +=
              "(proto_version '1', publication_names '$publicationName')";
          break;
        case LogicalDecodingPlugin.wal2json:
          statement += "(\"pretty-print\" 'false')";
          break;
      }

      // This future will not complete until the replication process stops
      // by closing the connection, an error or timing out.
      // ignore: unawaited_futures
      conn.execute(statement, timeoutInSeconds: 120).catchError((e) {
        // this query will be cancelled once the connection is closed.
        // no need to handle the error
        return 0;
      });

      await Future.delayed(Duration(seconds: 1));
    });

    tearDownAll(() async {
      // this will stop the streaming and delete the replication slot
      await conn.close();
      await conn2.close();
    });

    // BeginMessage -> InsertMessage -> CommitMessage
    test('- Receive InsertMessage after insert statement', () async {
      final stream = conn.messages
          .where((event) => event is XLogDataMessage)
          .map((event) => (event as XLogDataMessage).data)
          // RelationMessage isn't always present (appears conditionally) so
          // it's skipped when present
          .where((event) => event is! RelationMessage)
          .take(3);

      late final StreamController controller;
      controller = StreamController(
        onListen: () async {
          // don't await here otherwise what's after won't be executed.
          final future = controller.addStream(stream);
          await conn2.execute("insert into temp (value) values ('test');");
          await future;
          await controller.close();
        },
      );

      final matchers = [
        isA<BeginMessage>(),
        isA<InsertMessage>(),
        isA<CommitMessage>(),
      ];

      expect(controller.stream, emitsInAnyOrder(matchers));
    });

    // BeginMessage -> UpdateMessage -> CommitMessage
    test('- Receive UpdateMessage after update statement', () async {
      // insert data to be updated
      await conn2.execute("insert into temp (value) values ('update_test');");
      // wait to avoid capturing INSERT
      await Future.delayed(Duration(seconds: 3));
      final stream = conn.messages
          .where((event) => event is XLogDataMessage)
          .map((event) => (event as XLogDataMessage).data)
          // RelationMessage isn't always present (appears conditionally) so
          // it's skipped when present
          .where((event) => event is! RelationMessage)
          .take(3);

      late final StreamController controller;
      controller = StreamController(
        onListen: () async {
          // don't await here otherwise what's after won't be executed.
          final future = controller.addStream(stream);
          await conn2.execute(
            "update temp set value = 'updated_test_value'"
            "where value = 'update_test';",
          );
          await future;
          await controller.close();
        },
      );

      final matchers = [
        isA<BeginMessage>(),
        isA<UpdateMessage>(),
        isA<CommitMessage>(),
      ];

      expect(controller.stream, emitsInAnyOrder(matchers));
    });
    // BeginMessage -> DeleteMessage -> CommitMessage
    test('- Receive DeleteMessage after delete statement', () async {
      // create table to be truncated
      await conn2.execute("insert into temp (value) values ('update_test');");
      // wait to avoid capturing INSERT
      await Future.delayed(Duration(seconds: 3));
      final stream = conn.messages
          .where((event) => event is XLogDataMessage)
          .map((event) => (event as XLogDataMessage).data)
          // RelationMessage isn't always present (appears conditionally) so
          // it's skipped when present
          .where((event) => event is! RelationMessage)
          .take(3);

      late final StreamController controller;
      controller = StreamController(
        onListen: () async {
          // don't await here otherwise what's after won't be executed.
          final future = controller.addStream(stream);
          await conn2.execute(
            "delete from temp where value = 'update_test';",
          );
          await future;
          await controller.close();
        },
      );

      final matchers = [
        isA<BeginMessage>(),
        isA<DeleteMessage>(),
        isA<CommitMessage>(),
      ];

      expect(controller.stream, emitsInAnyOrder(matchers));
    });

    // BeginMessage -> TruncateMessage -> CommitMessage
    test('- Receive TruncateMessage after delete statement', () async {
      final tableName = 'temp_truncate';
      // insert data to be deleted
      await conn2.execute('''
create table if not exists $tableName (
    id int GENERATED ALWAYS AS IDENTITY, 
    value text,
    PRIMARY KEY (id)
    );
''');
      // wait to for a second
      await Future.delayed(Duration(seconds: 1));
      final stream = conn.messages
          .where((event) => event is XLogDataMessage)
          .map((event) => (event as XLogDataMessage).data)
          // RelationMessage isn't always present (appears conditionally) so
          // it's skipped when present
          .where((event) => event is! RelationMessage)
          .take(3);

      late final StreamController controller;
      controller = StreamController(
        onListen: () async {
          // don't await here otherwise what's after won't be executed.
          final future = controller.addStream(stream);
          await conn2.execute(
            'truncate table $tableName;',
          );
          await future;
          await controller.close();
        },
      );

      final matchers = [
        isA<BeginMessage>(),
        isA<TruncateMessage>(),
        isA<CommitMessage>(),
      ];

      expect(controller.stream, emitsInOrder(matchers));
    });
  });
}
