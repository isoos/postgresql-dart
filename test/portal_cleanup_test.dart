import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:postgres/postgres.dart';
import 'package:postgres/src/v3/protocol.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('portal cleanup', (server) {
    late Connection connection;
    late List<ClientMessage> sent;
    late List<ServerMessage> received;
    Completer<void>? readyHeld;
    Completer<void>? releaseReady;

    setUp(() async {
      sent = [];
      received = [];
      readyHeld = null;
      releaseReady = null;
      connection = await Connection.open(
        await server.endpoint(),
        settings: ConnectionSettings(
          transformer: StreamChannelTransformer<Message, Message>(
            StreamTransformer.fromBind(
              (messages) => messages.asyncMap((message) async {
                if (message is ReadyForQueryMessage && releaseReady != null) {
                  readyHeld!.complete();
                  await releaseReady!.future;
                }
                received.add(message as ServerMessage);
                return message;
              }),
            ),
            StreamSinkTransformer.fromHandlers(
              handleData: (message, sink) {
                if (message is AggregatedClientMessage) {
                  sent.addAll(message.messages);
                } else if (message is ClientMessage) {
                  sent.add(message);
                }
                sink.add(message);
              },
            ),
          ),
        ),
      );
      sent.clear();
      received.clear();
    });

    tearDown(() async {
      if (releaseReady case final gate? when !gate.isCompleted) {
        gate.complete();
      }
      await connection.close();
    });

    test('Given an extended query outside a transaction, '
        'when it completes, '
        'then its portal closes before the only Sync.', () async {
      final rows = await connection.execute('SELECT 42 AS answer');

      expect(rows, [
        [42],
      ]);
      expect(sent.map((m) => m.runtimeType), [
        ParseMessage,
        BindMessage,
        DescribeMessage,
        ExecuteMessage,
        CloseMessage,
        SyncMessage,
      ]);
      expect(_closeTargets(sent), ['Pp/0']);
      expect(received.map((m) => m.runtimeType), [
        ParseCompleteMessage,
        BindCompleteMessage,
        RowDescriptionMessage,
        DataRowMessage,
        CommandCompleteMessage,
        CloseCompleteMessage,
        ReadyForQueryMessage,
      ]);
    });

    test('Given an extended query with no rows in a transaction, '
        'when it completes, '
        'then its portal is gone without a second exchange.', () async {
      final snapshot = await connection.runTx((tx) async {
        sent.clear();
        received.clear();
        final rows = await tx.execute('SELECT 42 WHERE false');
        final requestTypes = sent.map((m) => m.runtimeType).toList();
        final responseTypes = received.map((m) => m.runtimeType).toList();
        final portals = await tx.execute(
          'SELECT name FROM pg_cursors',
          queryMode: QueryMode.simple,
        );
        return (rows, requestTypes, responseTypes, portals);
      });

      expect(snapshot.$1, isEmpty);
      expect(snapshot.$1.schema.columns, hasLength(1));
      expect(snapshot.$2, [
        ParseMessage,
        BindMessage,
        DescribeMessage,
        ExecuteMessage,
        CloseMessage,
        SyncMessage,
      ]);
      expect(snapshot.$3, [
        ParseCompleteMessage,
        BindCompleteMessage,
        RowDescriptionMessage,
        CommandCompleteMessage,
        CloseCompleteMessage,
        ReadyForQueryMessage,
      ]);
      expect(snapshot.$4, isEmpty);
    });

    test(
      'Given an extended query returning many rows, '
      'when it completes, '
      'then every row is delivered before portal cleanup finishes.',
      () async {
        final rows = await connection.runTx(
          (tx) => tx.execute('SELECT generate_series(1, 2000)'),
        );

        expect(
          rows.map((row) => row.single),
          List.generate(2000, (i) => i + 1),
        );
        expect(rows.affectedRows, 2000);
        expect(received.whereType<CloseCompleteMessage>(), hasLength(1));
      },
    );

    test('Given a simple query in a transaction, '
        'when it completes, '
        'then no portal cleanup or Sync is sent.', () async {
      final snapshot = await connection.runTx((tx) async {
        sent.clear();
        final rows = await tx.execute('SELECT 42', queryMode: QueryMode.simple);
        return (rows, sent.map((m) => m.runtimeType).toList());
      });

      expect(snapshot.$1, [
        [42],
      ]);
      expect(snapshot.$2, [QueryMessage]);
    });

    test(
      'Given a named prepared statement, '
      'when it runs twice in a transaction and is disposed, '
      'then each portal closes while the statement remains reusable.',
      () async {
        final statement = await connection.prepare(r'SELECT $1::int');
        sent.clear();

        final results = await connection.runTx((tx) async {
          final first = await statement.run([1]);
          final second = await statement.run([2]);
          return [first, second];
        });
        await statement.dispose();

        expect(results, [
          [
            [1],
          ],
          [
            [2],
          ],
        ]);
        expect(sent.whereType<ParseMessage>(), isEmpty);
        expect(_closeTargets(sent), ['Pp/0', 'Pp/1', 'Ss/0']);
        expect(sent.whereType<SyncMessage>(), hasLength(3));
      },
    );

    test(
      'Given CloseComplete followed by a withheld ReadyForQuery, '
      'when another query is queued, '
      'then the first query retains the connection until ReadyForQuery.',
      () async {
        readyHeld = Completer<void>();
        releaseReady = Completer<void>();
        var completed = false;

        final first = connection.execute('SELECT 1').then((rows) {
          completed = true;
          return rows;
        });
        await readyHeld!.future;
        final second = connection.execute('SELECT 2');
        await Future<void>.delayed(Duration.zero);
        final completedBeforeReady = completed;
        final requestsBeforeReady = sent.whereType<ExecuteMessage>().length;
        final closeCompletions = received
            .whereType<CloseCompleteMessage>()
            .length;
        final gate = releaseReady!;
        releaseReady = null;
        gate.complete();
        final results = await Future.wait([first, second]);

        expect(completedBeforeReady, isFalse);
        expect(requestsBeforeReady, 1);
        expect(closeCompletions, 1);
        expect(results, [
          [
            [1],
          ],
          [
            [2],
          ],
        ]);
      },
    );

    test(
      'Given an invalid SQL statement, '
      'when Parse fails before portal cleanup, '
      'then ReadyForQuery permits connection reuse without CloseComplete.',
      () async {
        await expectLater(
          connection.execute('SELECT FROM'),
          throwsA(isA<ServerException>()),
        );
        final responses = received.map((m) => m.runtimeType).toList();
        final rows = await connection.execute('SELECT 42');

        expect(responses, [ErrorResponseMessage, ReadyForQueryMessage]);
        expect(rows, [
          [42],
        ]);
      },
    );

    test(
      'Given a parameter that cannot be converted to integer, '
      'when Bind fails before portal cleanup, '
      'then ReadyForQuery permits connection reuse without CloseComplete.',
      () async {
        final statement = await connection.prepare(r'SELECT $1::int');
        addTearDown(statement.dispose);
        received.clear();

        await expectLater(
          statement.run(['invalid']),
          throwsA(isA<ServerException>()),
        );
        final responses = received.map((m) => m.runtimeType).toList();
        final rows = await statement.run([42]);

        expect(responses, [ErrorResponseMessage, ReadyForQueryMessage]);
        expect(rows, [
          [42],
        ]);
      },
    );

    test(
      'Given a query dividing by zero at execution, '
      'when Execute fails before portal cleanup, '
      'then ReadyForQuery permits connection reuse without CloseComplete.',
      () async {
        await expectLater(
          connection.execute(
            'SELECT 1 / value FROM generate_series(0, 0) AS value',
          ),
          throwsA(isA<ServerException>()),
        );
        final responses = received.map((m) => m.runtimeType).toList();
        final rows = await connection.execute('SELECT 42');

        expect(responses, [
          ParseCompleteMessage,
          BindCompleteMessage,
          RowDescriptionMessage,
          ErrorResponseMessage,
          ReadyForQueryMessage,
        ]);
        expect(rows, [
          [42],
        ]);
      },
    );

    test(
      'Given an inserted row in a transaction, '
      'when its callback throws after portal cleanup, '
      'then the insert rolls back and the connection remains usable.',
      () async {
        await connection.execute('CREATE TEMP TABLE writes (id int)');
        final error = StateError('abort callback');

        await expectLater(
          connection.runTx((tx) async {
            await tx.execute('INSERT INTO writes VALUES (1)');
            throw error;
          }),
          throwsA(same(error)),
        );
        final rows = await connection.execute('SELECT * FROM writes');

        expect(rows, isEmpty);
        expect(connection.isOpen, isTrue);
      },
    );

    test(
      'Given an inserted row in a transaction, '
      'when a subsequent SQL statement fails, '
      'then skipped portal cleanup does not prevent rollback and reuse.',
      () async {
        await connection.execute('CREATE TEMP TABLE writes (id int)');

        await expectLater(
          connection.runTx((tx) async {
            await tx.execute('INSERT INTO writes VALUES (1)');
            await tx.execute('SELECT 1/0');
          }),
          throwsA(isA<ServerException>()),
        );
        final rows = await connection.execute('SELECT * FROM writes');

        expect(rows, isEmpty);
        expect(connection.isOpen, isTrue);
      },
    );

    test(
      'Given a named statement running in a transaction, '
      'when its query times out, '
      'then cancellation drains and rollback permits statement reuse.',
      () async {
        await connection.execute('CREATE TEMP TABLE writes (id int)');
        final statement = await connection.prepare(
          r'SELECT pg_sleep($1::float8)',
        );
        addTearDown(statement.dispose);

        await expectLater(
          connection.runTx((tx) async {
            await tx.execute('INSERT INTO writes VALUES (1)');
            received.clear();
            await statement.run([5.0], timeout: Duration(milliseconds: 100));
          }),
          throwsA(allOf(isA<PgException>(), isA<TimeoutException>())),
        );
        final closeCompletions = received
            .whereType<CloseCompleteMessage>()
            .length;
        final reused = await statement.run([0.0]);
        final rows = await connection.execute('SELECT * FROM writes');

        expect(closeCompletions, 0);
        expect(reused, hasLength(1));
        expect(rows, isEmpty);
        expect(connection.isOpen, isTrue);
      },
    );

    test('Given a prepared row stream in a transaction, '
        'when its subscription is canceled after the first row, '
        'then the portal closes and the statement can run again.', () async {
      final statement = await connection.prepare(
        'SELECT generate_series(1, 2000)',
      );
      addTearDown(statement.dispose);

      final snapshot = await connection.runTx((tx) async {
        final firstRow = Completer<ResultRow>();
        late ResultStreamSubscription subscription;
        subscription = statement.bind([]).listen((row) {
          subscription.pause();
          firstRow.complete(row);
        });
        final first = await firstRow.future;
        await subscription.cancel();
        final portals = await tx.execute(
          'SELECT name FROM pg_cursors',
          queryMode: QueryMode.simple,
        );
        final rows = await statement.run([]);
        return (first, portals, rows);
      });

      expect(snapshot.$1, [1]);
      expect(snapshot.$2, isEmpty);
      expect(
        snapshot.$3.map((row) => row.single),
        List.generate(2000, (i) => i + 1),
      );
    });

    test(
      'Given a table receiving a server-side COPY, '
      'when COPY completes inside a transaction, '
      'then portal cleanup preserves copied rows and affected-row counts.',
      () async {
        await connection.execute('CREATE TEMP TABLE copied_rows (id int)');

        final copied = await connection.runTx((tx) async {
          await tx.execute(
            "COPY (SELECT generate_series(1, 3)) TO '/tmp/driver-copy-rows'",
          );
          return tx.execute("COPY copied_rows FROM '/tmp/driver-copy-rows'");
        });
        final rows = await connection.execute(
          'SELECT id FROM copied_rows ORDER BY id',
        );

        expect(copied, isEmpty);
        expect(copied.affectedRows, 3);
        expect(rows, [
          [1],
          [2],
          [3],
        ]);
      },
    );

    test('Given an encrypted connection, '
        'when an extended query runs, '
        'then TLS remains active through portal cleanup.', () async {
      final rows = await connection.execute(
        'SELECT ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid()',
      );

      expect(rows, [
        [true],
      ]);
      expect(received.whereType<CloseCompleteMessage>(), hasLength(1));
    });

    group('Given a row locked by an explicit transaction,', () {
      late Connection contender;

      setUp(() async {
        contender = await server.newConnection();
        await connection.execute(
          'CREATE TABLE locked_row (id int PRIMARY KEY)',
        );
        await connection.execute('INSERT INTO locked_row VALUES (1)');
      });

      tearDown(() async {
        await contender.close();
        await connection.execute('DROP TABLE locked_row');
      });

      test('when the portal closes and the transaction commits, '
          'then a competing lock is blocked until commit.', () async {
        await connection.runTx((tx) async {
          await tx.execute('SELECT * FROM locked_row FOR UPDATE');
          await expectLater(
            contender.execute('SELECT * FROM locked_row FOR UPDATE NOWAIT'),
            throwsA(
              isA<ServerException>().having((e) => e.code, 'code', '55P03'),
            ),
          );
        });
        final rows = await contender.execute(
          'SELECT * FROM locked_row FOR UPDATE NOWAIT',
        );

        expect(rows, [
          [1],
        ]);
      });

      test('when the portal closes and the transaction rolls back, '
          'then a competing lock is blocked until rollback.', () async {
        final error = StateError('rollback locked row');

        await expectLater(
          connection.runTx((tx) async {
            await tx.execute('SELECT * FROM locked_row FOR UPDATE');
            await expectLater(
              contender.execute('SELECT * FROM locked_row FOR UPDATE NOWAIT'),
              throwsA(
                isA<ServerException>().having((e) => e.code, 'code', '55P03'),
              ),
            );
            throw error;
          }),
          throwsA(same(error)),
        );
        final rows = await contender.execute(
          'SELECT * FROM locked_row FOR UPDATE NOWAIT',
        );

        expect(rows, [
          [1],
        ]);
      });
    });
  });
}

List<String> _closeTargets(List<ClientMessage> messages) => [
  for (final message in messages.whereType<CloseMessage>())
    // Include the P/S discriminator and name, excluding the trailing zero.
    utf8.decode(
      message
          .asBytes(encoding: utf8)
          .sublist(5)
          .takeWhile((b) => b != 0)
          .toList(),
    ),
];
