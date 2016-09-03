library postgres;

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

part 'src/client_messages.dart';
part 'src/server_messages.dart';
part 'src/postgresql_codec.dart';
part 'src/substituter.dart';
part 'src/connection.dart';
part 'src/message_window.dart';
part 'src/connection_fsm.dart';
part 'src/query.dart';

class PostgreSQLException implements Exception {
  PostgreSQLException(this.message);

  final String message;

  String toString() => message;
}