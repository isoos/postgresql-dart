/// Example for the `postgres` package.
///
/// Running the example requires access to a postgres server. If you have docker
/// installed, you can start a postgres server to run this example with
///
/// ```
/// docker run --detach --name postgres_for_dart_test -p 127.0.0.1:5432:5432 -e POSTGRES_USER=user -e POSTGRES_DATABASE=database -e POSTGRES_PASSWORD=pass postgres
/// ```
///
/// To stop and clear the database server once you're done testing, run
///
/// ```
/// docker container rm --force postgres_for_dart_test
/// ```
library;

import 'package:postgres/postgres.dart';

void main() async {
  final conn = await Connection.open(
    Endpoint(
      host: 'localhost',
      database: 'postgres',
      username: 'user',
      password: 'pass',
    ),
    // The postgres server hosted locally doesn't have SSL by default. If you're
    // accessing a postgres server over the Internet, the server should support
    // SSL and you should swap out the mode with `SslMode.verifyFull`.
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );
  print('has connection!');

  // Simple query without results
  await conn.execute('CREATE TABLE IF NOT EXISTS a_table ('
      '  id TEXT NOT NULL, '
      '  totals INTEGER NOT NULL DEFAULT 0'
      ')');

  // simple query
  final result0 = await conn.execute("SELECT 'foo'");
  print(result0[0][0]); // first row, first column

  // Using prepared statements to supply values
  final result1 = await conn.execute(
    r'INSERT INTO a_table (id) VALUES ($1)',
    parameters: ['example row'],
  );
  print('Inserted ${result1.affectedRows} rows');

  // name parameter query
  final result2 = await conn.execute(
    Sql.named('SELECT * FROM a_table WHERE id=@id'),
    parameters: {'id': 'example row'},
  );
  print(result2.first.toColumnMap());

  // transaction
  await conn.runTx((s) async {
    final rs = await s.execute('SELECT count(*) FROM a_table');
    await s.execute(
      r'UPDATE a_table SET totals=$1 WHERE id=$2',
      parameters: [rs[0][0], 'xyz'],
    );
  });

  // prepared statement
  final statement = await conn.prepare(Sql("SELECT 'foo';"));
  final result3 = await statement.run([]);
  print(result3);
  await statement.dispose();

  // preared statement with types
  final anotherStatement =
      await conn.prepare(Sql(r'SELECT $1;', types: [Type.bigInteger]));
  final bound = anotherStatement.bind([1]);
  final subscription = bound.listen((row) {
    print('row: $row');
  });
  await subscription.asFuture();
  await subscription.cancel();
  print(await subscription.affectedRows);
  print(await subscription.schema);

  await conn.close();
}