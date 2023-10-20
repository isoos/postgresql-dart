import 'package:postgres/postgres.dart';

void main() async {
  final conn = await Connection.open(Endpoint(
    host: 'localhost',
    database: 'postgres',
    username: 'user',
    password: 'pass',
  ));
  print('has connection!');

  // simple query
  final result0 = await conn.execute("SELECT 'foo'");
  print(result0[0][0]); // first row, first column

  // name parameter query
  final result1 = await conn.execute(
    Sql.named('SELECT * FROM a_table WHERE id=@id'),
    parameters: {'id': 'xyz'},
  );
  print(result1.first.toColumnMap());

  // transaction
  await conn.runTx((s) async {
    final rs = await s.execute('SELECT count(*) FROM foo');
    await s.execute(
      r'UPDATE a_table SET totals=$1 WHERE id=$2',
      parameters: [rs[0][0], 'xyz'],
    );
  });

  // prepared statement
  final statement = await conn.prepare(Sql("SELECT 'foo';"));
  final result2 = await statement.run([]);
  print(result2);
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
