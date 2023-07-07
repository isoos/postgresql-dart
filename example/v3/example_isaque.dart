//import 'dart:convert';

import 'package:enough_convert/enough_convert.dart';
import 'package:postgres/postgres.dart';

void main() async {
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'siamweb',
    username: 'sisadmin',
    password: 's1sadm1n',
    encoding: Windows1252Codec(allowInvalid: false),
  );
  await connection.open();

  await connection.query('''SET client_encoding = 'win1252';''');

  await connection.query(''' INSERT INTO  public.sw_processos_favoritos
  (cod_processo,ano_exercicio,numcgm,data_cadastro,descricao)
  VALUES (3057,1198,140050,'2023-07-06',@des:varchar) ''',substitutionValues:{'des':'João Já é '});

  final results = await connection.mappedResultsQuery(
      ' SELECT * FROM public.sw_processos_favoritos  ORDER BY id desc LIMIT 10');

  for (final row in results) {
    print('$row');
  }
}
