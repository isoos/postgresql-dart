import 'dart:typed_data';

import '../types.dart';
import 'binary_codec.dart';
import 'text_codec.dart';

class UnknownType extends Type<Object> {
  UnknownType(super.oid);

  @override
  EncodeOutput encode(EncodeInput input) {
    final v = input.value;
    if (v is Uint8List) {
      return EncodeOutput.bytes(v);
    } else if (v is String) {
      return EncodeOutput.text(v);
    }
    throw UnimplementedError(
        'Encoding ${v.runtimeType} for oid:$oid is not supported.');
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
  EncodeOutput encode(EncodeInput input) {
    if (hasOid) {
      final encoder = PostgresBinaryEncoder(oid!);
      final bytes = encoder.convert(input.value, input.encoding);
      return EncodeOutput.bytes(bytes);
    } else {
      const converter = PostgresTextEncoder();
      final text = converter.convert(input.value, escapeStrings: false);
      return EncodeOutput.text(text);
    }
  }

  @override
  Object? decode(DecodeInput input) {
    if (input.isBinary) {
      return PostgresBinaryDecoder(oid!).convert(input.bytes, input.encoding);
    } else {
      return PostgresTextDecoder(oid!).convert(input);
    }
  }
}
