import 'dart:convert';
import 'dart:typed_data';

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

class GenericTypeCodec extends TypeCodec<Object> {
  final int oid;

  GenericTypeCodec(
    this.oid, {
    super.encodesNull,
    super.decodesNull,
  });

  @override
  EncodedValue encode(TypeCodecContext context, Object? value) {
    final encoder = PostgresBinaryEncoder(oid);
    final bytes = encoder.convert(value, context.encoding);
    return EncodedValue(bytes: bytes, isBinary: true);
  }

  @override
  Object? decode(TypeCodecContext context, EncodedValue input) {
    if (input.isBinary) {
      return PostgresBinaryDecoder.convert(context, oid, input.bytes!);
    } else {
      return PostgresTextDecoder.convert(context, oid, input.bytes!);
    }
  }
}
