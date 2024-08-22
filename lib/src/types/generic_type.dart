import 'dart:convert';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:postgres/src/buffer.dart';

import '../types.dart';
import 'binary_codec.dart';
import 'text_codec.dart';
import 'type_registry.dart';

class EncodedValue {
  final Uint8List? bytes;
  final bool isBinary;

  EncodedValue({
    required this.bytes,
    required this.isBinary,
  });
}

class TypeCodecContext {
  final Encoding encoding;
  final TypeRegistry typeRegistry;

  TypeCodecContext({
    required this.encoding,
    required this.typeRegistry,
  });

  PgByteDataReader newPgByteDataReader([Uint8List? bytes]) {
    final reader = PgByteDataReader(encoding: encoding);
    if (bytes != null) {
      reader.add(bytes);
    }
    return reader;
  }

  PgByteDataWriter newPgByteDataWriter() {
    return PgByteDataWriter(encoding: encoding);
  }
}

class UnknownType extends Type<Object> {
  const UnknownType(super.oid);
}

class UnspecifiedType extends Type<Object> {
  const UnspecifiedType() : super(null);
}

/// NOTE: do not use this type in client code.
class GenericType<T extends Object> extends Type<T> {
  const GenericType(super.oid);
}

extension GenericTypeExt<T extends Object> on GenericType<T> {
  EncodedValue encode(TypeCodecContext context, Object? value) {
    if (oid != null && oid! > 0) {
      final encoder = PostgresBinaryEncoder(oid!);
      final bytes = encoder.convert(value, context.encoding);
      return EncodedValue(bytes: bytes, isBinary: true);
    } else {
      const converter = PostgresTextEncoder();
      final text = converter.convert(value, escapeStrings: false);
      return EncodedValue(
          bytes: castBytes(context.encoding.encode(text)), isBinary: false);
    }
  }

  T? decode(TypeCodecContext context, EncodedValue input) {
    if (input.isBinary) {
      return PostgresBinaryDecoder.convert(context, oid!, input.bytes!) as T?;
    } else {
      return PostgresTextDecoder.convert(context, oid!, input.bytes!) as T?;
    }
  }
}
