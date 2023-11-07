import 'dart:convert';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import '../types.dart';
import 'binary_codec.dart';
import 'text_codec.dart';

/// NOTE: do not use this type in client code.
class GenericType<T extends Object> extends Type<T> {
  const GenericType(
    super.oid, {
    super.nameForSubstitution,
  });

  @override
  Uint8List? encodeAsBytes(Object? value, Encoding encoding) {
    if (hasOid) {
      final encoder = PostgresBinaryEncoder(oid!);
      return encoder.convert(value, encoding);
    }
    if (value != null) {
      const converter = PostgresTextEncoder();
      return castBytes(
          encoding.encode(converter.convert(value, escapeStrings: false)));
    }
    return null;
  }

  @override
  Object? decodeFromBytes(
      Uint8List? value, Encoding encoding, bool isBinaryEncoding) {
    if (isBinaryEncoding) {
      return PostgresBinaryDecoder(oid!).convert(value, encoding);
    } else {
      return PostgresTextDecoder(oid!).convert(value, encoding);
    }
  }
}
