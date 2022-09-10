import 'dart:async';
import 'dart:io';

import 'package:postgres/messages.dart';
import 'package:postgres/postgres.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'docker.dart';

void main() {
  // Running these tests on the CI will fail since the the `SetUpAll` function
  // alter systems configuration (i.e. wal_level, max_replication_slots, max_wal_senders)
  // which requires reloading the database changes. The only known possible way to do that
  // now is to restart the docker container which apparently won't work on the CI
  //
  // TODO: enable replication configuration before spinning up the container
  //       i.e. pre-set wal_level, max_replication_slots, max_wal_senders in
  //       `postgresql.conf` file
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
    var replicationConn = PostgreSQLConnection(
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

    setUpAll(() async {
      await replicationConn.open();

      // Setup the database for replication
      await replicationConn.execute('ALTER SYSTEM SET wal_level = logical;');
      await replicationConn
          .execute('ALTER SYSTEM SET max_replication_slots = 5;');
      await replicationConn.execute('ALTER SYSTEM SET max_wal_senders=5;');

      /// 'ALTER SYSTEM' statement requires restarting the database
      /// An easy way is to restart the docker container
      await replicationConn.close();

      // This is a temp work around until a better way is found
      // Adding this to `docker.dart` can be problmatic since it should not be
      // used in tests that run on the CI.
      // TODO: remove this once an alternative method is found
      await Process.run('docker', ['restart', 'postgres-dart-test']);

      // it is necessary re-construct the object as calling `conn.open()` won't work
      replicationConn = PostgreSQLConnection(
        _host,
        _port,
        _database,
        username: _username,
        password: _password,
        replicationMode: replicationMode,
      );

      // wait for a second then open the connections.
      await Future.delayed(Duration(seconds: 1));
      await replicationConn.open();
      await changesConn.open();

      // create a temp table for testing
      await replicationConn.execute('create table if not exists temp'
          '(id int GENERATED ALWAYS AS IDENTITY, value text,'
          'PRIMARY KEY (id));');

      // create publication
      final publicationName = 'test_publication';
      await replicationConn
          .execute('DROP PUBLICATION IF EXISTS $publicationName;');
      await replicationConn
          .execute('CREATE PUBLICATION $publicationName FOR ALL TABLES;');

      final sysInfoRes = await replicationConn.query('IDENTIFY_SYSTEM;',
          useSimpleQueryProtocol: true);

      final xlogpos = sysInfoRes.first.toColumnMap()['xlogpos'] as String;

      // create replication slot
      final slotName = 'a_test_slot';

      // `TEMPORARY` will remove the slot after the connection is closed/dropped
      await replicationConn.execute(
        'CREATE_REPLICATION_SLOT $slotName TEMPORARY LOGICAL'
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
              .execute("insert into temp (value) values ('test');");
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
          .execute("insert into temp (value) values ('update_test');");
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
      await changesConn
          .execute("insert into temp (value) values ('update_test');");
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
      await changesConn.execute('''
create table if not exists $tableName (
    id int GENERATED ALWAYS AS IDENTITY, 
    value text,
    PRIMARY KEY (id)
    );
''');
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
