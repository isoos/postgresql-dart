//import 'dart:convert';
import 'dart:async';
//import 'package:enough_convert/enough_convert.dart';
import 'package:postgres/postgres.dart';

void main(List<String> args) {
  Timer.periodic(Duration(milliseconds: 500), (timer) {
    exec();
  });
}

void exec() async {
  final connection = PostgreSQLConnection(
    '10.0.0.25',
    5432,
    'siamweb',
    username: 'sisadmin',
    password: 's1sadm1n',
    //encoding: Windows1252Codec(allowInvalid: false),
  );
  await connection.open();

  await connection.query('''SET client_encoding = 'win1252';''');
  // print('affectedRowCount: ${queryResult1.affectedRowCount}');
  // final now1 = DateTime.parse('2023-07-14 12:05:16');
  //final now1 = DateTime.now();
  final now1 = DateTime.parse(DateTime.now().toIso8601String());

  final res = await connection.query(
      ''' INSERT INTO  public.sw_processos_favoritos
  (cod_processo,ano_exercicio,numcgm,data_cadastro,descricao)
  VALUES (3057,1198,140050, ? , ? ) returning id''',
      substitutionValues: [now1, 'João Já é 2023'],
      placeholderIdentifier: PlaceholderIdentifier.onlyQuestionMark);

  print('res $res');

  final res2 = await connection.transaction((ctx) {
    return ctx.query(' SELECT * FROM public.sw_processos_favoritos WHERE id=? ',
        substitutionValues: [res.first.first],
        allowReuse: true,
        timeoutInSeconds: 10,
        placeholderIdentifier: PlaceholderIdentifier.onlyQuestionMark);
  });

  print('res $res2');

  // final results = await connection.mappedResultsQuery(
  //     ' SELECT * FROM public.sw_processos_favoritos  ORDER BY id desc LIMIT @limite',
  //     substitutionValues: {'limite': 10},
  //     placeholderIdentifier: PlaceholderIdentifier.atSign);

  await connection.close();
}
