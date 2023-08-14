# postgres example

## v2 API

```dart
import 'package:enough_convert/enough_convert.dart';
import 'package:postgres/postgres.dart';

void main(List<String> args) async {
  // create connection
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'data_base',
    username: 'postgres',
    password: 'pass',
    encoding: Windows1252Codec(allowInvalid: false),
  );
  // open connection
  await connection.open();
  // set client_encoding
  await connection.query('''SET client_encoding = 'win1252';''');

  final now1 = DateTime.parse(DateTime.now().toIso8601String());

  // execute insert  
  final res = await connection.query(''' INSERT INTO public.favorites
  (id,date_register,description)
  VALUES (10, ? , ? ) returning id''',
      substitutionValues: [now1, 'City Hall of São Paulo - Brazil'],
      placeholderIdentifier: PlaceholderIdentifier.onlyQuestionMark);

  print('result: $res');

  // execute transaction with select
  final res2 = await connection.transaction((ctx) {
    return ctx.query(' SELECT * FROM public.favorites WHERE id=? ',
        substitutionValues: [res.first.first],
        allowReuse: true,
        timeoutInSeconds: 10,
        placeholderIdentifier: PlaceholderIdentifier.onlyQuestionMark);
  });

  print('result: $res2');

  // execute select and returning as map
  final res3 = await connection.mappedResultsQuery(
      ' SELECT * FROM public.favorites ORDER BY id desc LIMIT @limite',
      substitutionValues: {'limite': 10},
      placeholderIdentifier: PlaceholderIdentifier.atSign);

  print('result: $res3');

  await connection.close();
}


```


## v3 API

```dart
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
}


```