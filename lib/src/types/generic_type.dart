import 'dart:convert';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import '../types.dart';
import 'binary_codec.dart';
import 'text_codec.dart';

class UnknownType extends Type<Object> {
  UnknownType(super.oid);

  @override
  Uint8List? encodeAsBytes(Object value, Encoding encoding) {
    if (value is Uint8List) {
      return value;
    }
    throw UnimplementedError(
        'Encoding ${value.runtimeType} for oid:$oid is not supported.');
  }

  @override
  Object? decodeFromBytes(
      Uint8List value, Encoding encoding, bool isBinaryEncoding) {
    if (hasOid && isBinaryEncoding) {
      return TypedBytes(typeOid: oid!, bytes: value);
    }
    throw UnimplementedError('Decoding of oid:$oid not supported.');
  }
}

/// NOTE: do not use this type in client code.
class GenericType<T extends Object> extends Type<T> {
  const GenericType(
    super.oid, {
    super.nameForSubstitution,
  });

  @override
  Uint8List? encodeAsBytes(Object value, Encoding encoding) {
    if (canEncodeAsBinary) {
      final encoder = PostgresBinaryEncoder(oid!);
      return encoder.convert(value, encoding);
    } else {
      const converter = PostgresTextEncoder();
      return castBytes(
          encoding.encode(converter.convert(value, escapeStrings: false)));
    }
  }

  @override
  Object? decodeFromBytes(
      Uint8List value, Encoding encoding, bool isBinaryEncoding) {
    if (isBinaryEncoding) {
      return PostgresBinaryDecoder(oid!).convert(value, encoding);
    } else {
      return PostgresTextDecoder(oid!).convert(value, encoding);
    }
  }
}
