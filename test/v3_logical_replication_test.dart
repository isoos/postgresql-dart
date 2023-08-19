import 'dart:async';

import 'package:async/async.dart';
import 'package:postgres/messages.dart';
import 'package:postgres/postgres.dart';
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'docker.dart';

/// An Interceptor that listens to server events
class _ServerMessagesInterceptor {
  final controller = StreamController<ServerMessage>.broadcast();

  Stream<ServerMessage> get messages => controller.stream;

  // For the current set of tests, we are only listening to server events and
  // we are not sending anything to the server so the second handler is left
  // empty
  late final transformer = StreamChannelTransformer<BaseMessage, BaseMessage>(
    StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        if (!controller.isClosed) {
          controller.add(data as ServerMessage);
        }
        sink.add(data);
      },
    ),
    StreamSinkTransformer.fromHandlers(),
  );
}

void main() {
  usePostgresDocker();

  // NOTES:
  // - Two PostgreSQL connections are needed for testing replication.
  //    - One for listening to streaming replications (this connection will be locked).
  //    - The other one to modify the database (e.g. insert, delete, update, truncate)
  group('test logical replication with pgoutput for decoding', () {
    // use this for listening to messages
    late final PgConnection replicationConn;

    // use this for sending queries
    late final PgConnection changesConn;

    // used to intercept server messages in the replication connection
    // the interceptor is used by tests to listen to replication stream
    final serverMessagesInterceptor = _ServerMessagesInterceptor();

    // this table is for insert, update, and delete tests.
    final changesTable = 'test.temp_changes_table';

    // this will be used for testing truncation
    // must be created before hand to add in publication
    final truncateTable = 'test.temp_truncate_table';

    setUpAll(() async {
      // connection setup

      // replication connection setup
      // used for creating replication slot and listening to changes in the db
      replicationConn = await PgConnection.open(
        PgEndpoint(
          host: 'localhost',
          database: 'dart_test',
          username: 'replication',
          password: 'replication',
        ),
        sessionSettings: PgSessionSettings(
            replicationMode: ReplicationMode.logical,
            onBadSslCertificate: (cert) => true,
            transformer: serverMessagesInterceptor.transformer,
            queryMode: QueryMode.simple),
      );

      // changes connection setup
      // used to create changes in the db that are reflected in the replication
      // stream
      changesConn = await PgConnection.open(
        PgEndpoint(
          host: 'localhost',
          database: 'dart_test',
          username: 'dart',
          password: 'dart',
        ),
        sessionSettings: PgSessionSettings(
          onBadSslCertificate: (cert) => true,
        ),
      );

      // create testing tables
      // note: primary keys are necessary for replication to work and they are
      //       used as an identity replica (to allow update & delete) on tables
      //       that are part of a publication.
      await changesConn.execute('create schema test');
      await changesConn.execute('create table $changesTable '
          '(id int GENERATED ALWAYS AS IDENTITY, value text, '
          'PRIMARY KEY (id));');
      await changesConn.execute('create table $truncateTable '
          '(id int GENERATED ALWAYS AS IDENTITY, value text, '
          'PRIMARY KEY (id));');

      // create publication
      final publicationName = 'test_publication';
      await changesConn.execute('DROP PUBLICATION IF EXISTS $publicationName;');
      await changesConn.execute(
        'CREATE PUBLICATION $publicationName FOR TABLE $changesTable, $truncateTable;',
      );

      final sysInfoRes = await replicationConn.execute('IDENTIFY_SYSTEM;');

      final xlogpos = sysInfoRes[0][2] as String;

      // create replication slot
      final slotName = 'a_test_slot';

      // the logical decoding used for testing
      final logicalDecodingPlugin = 'pgoutput';

      // `TEMPORARY` will remove the slot after the connection is closed/dropped
      await replicationConn
          .execute('CREATE_REPLICATION_SLOT $slotName TEMPORARY LOGICAL '
              '$logicalDecodingPlugin NOEXPORT_SNAPSHOT');

      // start replication process
      final statement = 'START_REPLICATION SLOT $slotName LOGICAL $xlogpos '
          "(proto_version '1', publication_names '$publicationName')";

      await replicationConn.execute(statement);
    });

    tearDownAll(() async {
      await replicationConn.close();
      await changesConn.close();
      await serverMessagesInterceptor.controller.close();
    });

    // BeginMessage -> InsertMessage -> CommitMessage
    test('- Receive InsertMessage after insert statement', () async {
      final stream = serverMessagesInterceptor.messages
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
      final stream = serverMessagesInterceptor.messages
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
      final stream = serverMessagesInterceptor.messages
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
      final stream = serverMessagesInterceptor.messages
          .where((event) {
            return event is XLogDataMessage;
          })
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
