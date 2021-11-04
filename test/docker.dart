import 'dart:io';

import 'package:docker_process/containers/postgres.dart';
import 'package:test/test.dart';

const _kContainerName = 'postgres-dart-test';

Future<void> startPostgresContainer() async {
  setUpAll(() async {
    if (Platform.environment.containsKey('GITHUB_ACTION')) {
      // Postgres already running
      return;
    }

    final isRunning = await isPostgresContainerRunning();
    if (isRunning) {
      return;
    }

    await startPostgres(
      name: _kContainerName,
      version: 'latest',
      pgPort: 5432,
      pgDatabase: 'dart_test',
      pgUser: 'dart',
      pgPassword: 'dart',
      cleanup: true,
    );
  });
}

Future<bool> isPostgresContainerRunning() async {
  final pr = await Process.run(
    'docker',
    ['ps', '--format', '{{.Names}}'],
  );
  return pr.stdout.toString().split('\n').map((s) => s.trim()).contains(_kContainerName);
}
