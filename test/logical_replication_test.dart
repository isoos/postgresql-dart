import 'dart:async';
import 'dart:io';

import 'package:postgres/messages.dart';
import 'package:postgres/postgres.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'docker.dart';

void main() {
  // Running these tests on the CI will not work as there is no way to pass
  // image arguments to the `services.postgres` container of github actions.
  //
  // TODO: Find a solution to spin up a postgres container where one can enable
  //       the replication configuration before spinning up the container either
  //       by passing image arguments or restarting the container after altering
  //       the database configurations (required for replication configs).
  if (Platform.environment.containsKey('GITHUB_ACTION')) {
    test('NO LOGICAL REPLICATION TESTS ARE RUNNING.', () {
      // no-op
    });
    return;
  }

  usePostgresDocker();

  // NOTES:
  // - Two PostgreSQL connections are needed for testing replication.
  //    - One for listening to streaming replications (this connection will be locked).
  //    - The other one to modify the database (e.g. insert, delete, update, truncate)
  group('test logical replication with pgoutput for decoding', () {
    final _host = 'localhost';
    final _port = 5432;
    final _username = 'dart';
    final _password = 'dart';
    final _database = 'dart_test';

    final logicalDecodingPlugin = 'pgoutput';
    final replicationMode = ReplicationMode.logical;
    // use this for listening to messages
    final replicationConn = PostgreSQLConnection(
      _host,
      _port,
      _database,
      username: _username,
      password: _password,
      replicationMode: replicationMode,
    );

    // use this for sending queries
    final changesConn = PostgreSQLConnection(
      _host,
      _port,
      _database,
      username: _username,
      password: _password,
    );

    // this table is for insert, update, and delete tests.
    final changesTable = 'temp_changes_table';
    // this will be used for testing truncation
    // must be created before hand to add in publication
    final truncateTable = 'temp_truncate_table';

    setUpAll(() async {
      await replicationConn.open();
      await changesConn.open();

      // create testing tables
      // note: primary keys are necessary for replication to work and they are
      //       used as an identity replica (to allow update & delete) on tables
      //       that are part of a publication.
      await replicationConn.execute('create table $changesTable '
          '(id int GENERATED ALWAYS AS IDENTITY, value text, '
          'PRIMARY KEY (id));');
      await replicationConn.execute('create table $truncateTable '
          '(id int GENERATED ALWAYS AS IDENTITY, value text, '
          'PRIMARY KEY (id));');

      // create publication
      final publicationName = 'test_publication';
      await replicationConn
          .execute('DROP PUBLICATION IF EXISTS $publicationName;');
      await replicationConn.execute(
        'CREATE PUBLICATION $publicationName FOR TABLE $changesTable, $truncateTable;',
      );

      final sysInfoRes = await replicationConn.query('IDENTIFY_SYSTEM;',
          useSimpleQueryProtocol: true);

      final xlogpos = sysInfoRes.first.toColumnMap()['xlogpos'] as String;

      // create replication slot
      final slotName = 'a_test_slot';

      // `TEMPORARY` will remove the slot after the connection is closed/dropped
      await replicationConn.execute(
        'CREATE_REPLICATION_SLOT $slotName TEMPORARY LOGICAL '
        '$logicalDecodingPlugin NOEXPORT_SNAPSHOT',
      );

      // start replication process
      final statement = 'START_REPLICATION SLOT $slotName LOGICAL $xlogpos '
          "(proto_version '1', publication_names '$publicationName')";

      // This future will not complete until the replication process stops
      // by closing the connection, an error or timing out.
      // ignore: unawaited_futures
      replicationConn.execute(statement, timeoutInSeconds: 120).catchError((e) {
        // this query will be cancelled once the connection is closed.
        // no need to handle the error
        return 0;
      });

      await Future.delayed(Duration(seconds: 1));
    });

    tearDownAll(() async {
      // this will stop the streaming and delete the replication slot
      await replicationConn.close();
      await changesConn.close();
    });

    // BeginMessage -> InsertMessage -> CommitMessage
    test('- Receive InsertMessage after insert statement', () async {
      final stream = replicationConn.messages
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
          await changesConn
              .execute("insert into $changesTable (value) values ('test');");
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
      await changesConn
          .execute("insert into $changesTable (value) values ('update_test');");
      // wait to avoid capturing INSERT
      await Future.delayed(Duration(seconds: 3));
      final stream = replicationConn.messages
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
          await changesConn.execute(
            "update $changesTable set value = 'updated_test_value'"
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
      // insert data to be delete
      await changesConn
          .execute("insert into $changesTable (value) values ('update_test');");
      // wait to avoid capturing INSERT
      await Future.delayed(Duration(seconds: 3));
      final stream = replicationConn.messages
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
          await changesConn.execute(
            "delete from $changesTable where value = 'update_test';",
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
      // wait to for a second
      await Future.delayed(Duration(seconds: 1));
      final stream = replicationConn.messages
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
          await changesConn.execute(
            'truncate table $truncateTable;',
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
