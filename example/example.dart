import 'package:postgres/postgres.dart';

void main() async {
  final endpoint = PgEndpoint(
    host: 'localhost',
    database: 'postgres',
    username: 'user',
    password: 'pass',
  );
  final conn = await PgConnection.open(endpoint);
  print('has connection!');

  // simple query
  final result = await conn.execute("SELECT 'foo'");
  print(result.first.toColumnMap());

  // prepared statement
  final statement = await conn.prepare(Sql("SELECT 'foo';"));
  final result2 = await statement.run([]);
  print(result2);
  await statement.dispose();

  // preared statement with types
  final anotherStatement =
      await conn.prepare(Sql(r'SELECT $1;', types: [DataType.bigInteger]));
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
