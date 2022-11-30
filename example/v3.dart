import 'package:postgres/postgres_v3_experimental.dart';

void main() async {
  final database = PgEndpoint(host: 'localhost', database: 'postgres');
  final connection = await database.connect();
  print('has connection!');

  final statement =
      await connection.prepare(PgQueryDescription.direct(r"SELECT 'foo';"));
  print('has statement');

  final stream = statement.start([]);
  print(await stream.schema);

  stream.listen(print);
}
