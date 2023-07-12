//import 'dart:convert';

import 'dart:async';

//import 'package:enough_convert/enough_convert.dart';
import 'package:postgres/postgres.dart';

void main() async {
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'siamweb',
    username: 'sisadmin',
    password: 's1sadm1n',
    //encoding: Windows1252Codec(allowInvalid: false),
  );
  await connection.open();

  //await connection.query('''SET client_encoding = 'win1252';''');
  // print('affectedRowCount: ${queryResult1.affectedRowCount}');

  // final queryResult2 = await connection.query(
  //     ''' INSERT INTO  public.sw_processos_favoritos
  // (cod_processo,ano_exercicio,numcgm,data_cadastro,descricao)
  // VALUES (3057,1198,140050,'2023-07-06',@des:varchar) ''',
  //     substitutionValues: {'des': 'João Já é 2023'});

  //print('affectedRowCount: ${queryResult2.affectedRowCount}');

  Timer.periodic(Duration(milliseconds: 10), ((timer) async {
    final results = await connection.query(
        ' SELECT * FROM public.sw_processo LIMIT ?',
        substitutionValues: [2000],allowReuse:true,timeoutInSeconds:10,
        placeholderIdentifier: PlaceholderIdentifier.onlyQuestionMark);

    // final results = await connection.mappedResultsQuery(
    //     ' SELECT * FROM public.sw_processos_favoritos  ORDER BY id desc LIMIT @limite',
    //     substitutionValues: {'limite': 10},
    //     placeholderIdentifier: PlaceholderIdentifier.atSign);

    for (final row in results) {
      print('$row');
    }
  }));
}
