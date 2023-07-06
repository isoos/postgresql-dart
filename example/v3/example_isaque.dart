import 'dart:convert';

import 'package:enough_convert/enough_convert.dart';
import 'package:postgres/postgres.dart';

void main() async {
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'siamweb',
    username: 'sisadmin',
    password: 's1sadm1n',
    encoding: Windows1252Codec(allowInvalid: true),
  );
  await connection.open();

  final results =
      await connection.query(' SELECT * FROM public.sw_processo LIMIT 10 ');

  for (final row in results) {
    print('row $row');
  }
}
