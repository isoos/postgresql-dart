import 'dart:typed_data';

import '../types.dart';
import 'binary_codec.dart';
import 'text_codec.dart';

class UnknownType extends Type<Object> {
  UnknownType(super.oid);

  @override
  EncodeOutput encode(Object input, CodecContext context) {
    if (input is Uint8List) {
      return EncodeOutput.bytes(input);
    } else if (input is String) {
      return EncodeOutput.text(input);
    }
    throw UnimplementedError(
        'Encoding ${input.runtimeType} for oid:$oid is not supported.');
  }

  @override
  Object? decode(DecodeInput input) {
    return TypedBytes(typeOid: oid ?? 0, bytes: input.bytes);
  }
}

/// NOTE: do not use this type in client code.
class GenericType<T extends Object> extends Type<T> {
  const GenericType(
    super.oid, {
    super.nameForSubstitution,
  });

  @override
  EncodeOutput encode(Object input, CodecContext context) {
    if (hasOid) {
      final encoder = PostgresBinaryEncoder(oid!);
      final bytes = encoder.convert(input, context.encoding);
      return EncodeOutput.bytes(bytes);
    } else {
      const converter = PostgresTextEncoder();
      final text = converter.convert(input, escapeStrings: false);
      return EncodeOutput.text(text);
    }
  }

  @override
  Object? decode(DecodeInput input) {
    if (input.isBinary) {
      return PostgresBinaryDecoder(oid!)
          .convert(input.bytes, input.context.encoding);
    } else {
      return PostgresTextDecoder(oid!).convert(input);
    }
  }
}
