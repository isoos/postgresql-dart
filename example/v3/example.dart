//import 'package:enough_convert/windows.dart';
import 'package:postgres/postgres_v3_experimental.dart';

void main() async {
  final database = PgEndpoint(host: 'localhost', database: 'postgres');
  final connection = await PgConnection.open(database);
  print('has connection!');

  final statement = await connection.prepare(PgSql(r"SELECT 'foo';"));
  print('has statement');
  final result = await statement.run(null);
  print(result);
  await statement.dispose();

  final anotherStatement = await connection
      .prepare(PgSql(r'SELECT $1;', types: [PgDataType.bigInteger]));
  final bound = anotherStatement.bind([1]);
  final subscription = bound.listen((row) {
    print('row: $row');
  });
  await subscription.asFuture();
  await subscription.cancel();
  print(await subscription.affectedRows);
  print(await subscription.schema);

  await connection.close();
  // example win1252
  // final database = PgEndpoint(
  //   host: 'localhost',
  //   database: 'database',
  //   username: 'user',
  //   password: 'pass',
  //   encoding: Windows1252Codec(allowInvalid: false),
  // );
  // final connection = await PgConnection.open(database);
  // final result = await connection.execute(
  //     'SELECT * FROM public.sw_processos_favoritos  ORDER BY id desc LIMIT 10');
  // print('result $result');
}
