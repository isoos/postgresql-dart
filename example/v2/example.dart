import 'package:postgres/postgres.dart';

void main(List<String> args) async {
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'data_base',
    username: 'postgres',
    password: 'pass',  
  );
  await connection.open();

  await connection.query('''SET client_encoding = 'win1252';''');

  final now1 = DateTime.parse(DateTime.now().toIso8601String());

  final res = await connection.query(''' INSERT INTO public.favorites
  (id,date_register,description)
  VALUES (10, ? , ? ) returning id''',
      substitutionValues: [now1, 'City Hall of São Paulo - Brazil'],
      placeholderIdentifier: PlaceholderIdentifier.onlyQuestionMark);

  print('result: $res');

  final res2 = await connection.transaction((ctx) {
    return ctx.query(' SELECT * FROM public.favorites WHERE id=? ',
        substitutionValues: [res.first.first],
        allowReuse: true,
        timeoutInSeconds: 10,
        placeholderIdentifier: PlaceholderIdentifier.onlyQuestionMark);
  });

  print('result: $res2');

  final res3 = await connection.mappedResultsQuery(
      ' SELECT * FROM public.favorites ORDER BY id desc LIMIT @limite',
      substitutionValues: {'limite': 10},
      placeholderIdentifier: PlaceholderIdentifier.atSign);

  print('result: $res3');

  await connection.close();
}
