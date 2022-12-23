import 'package:postgres/postgres_v3_experimental.dart';

void main() async {
  final database = PgEndpoint(host: 'localhost', database: 'postgres');
  final connection = await database.connect();
  print('has connection!');

  final statement =
      await connection.prepare(PgQueryDescription.direct(r"SELECT 'foo';"));
  print('has statement');
  final result = await statement.run(null);
  print(result);
  await statement.dispose();

  final anotherStatement = await connection.prepare(
      PgQueryDescription.direct(r'SELECT $1;', types: [PgDataType.bigInteger]));
  final bound = anotherStatement.bind([1]);
  final subscription = bound.listen((row) {
    print('row: $row');
  });
  await subscription.asFuture();
  await subscription.cancel();
  print(await subscription.affectedRows);
  print(await subscription.schema);
}
