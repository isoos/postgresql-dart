import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  // The driver does not run in a browser, but an app sharing code between its
  // server and its web client still compiles it there.
  test('public libraries compile to JavaScript', () async {
    final dir = await Directory.systemTemp.createTemp('postgres_js_compile');
    addTearDown(() => dir.delete(recursive: true));

    final entryPoint = File(p.join(dir.path, 'main.dart'));
    await entryPoint.writeAsString('''
import 'package:postgres/messages.dart';
import 'package:postgres/postgres.dart';

void main() {}
''');

    final packageConfig = (await Isolate.packageConfig)!;
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '--packages=${packageConfig.toFilePath()}',
      '--output=${p.join(dir.path, 'main.js')}',
      entryPoint.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });
}
