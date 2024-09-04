import '../types.dart';
import 'binary_codec.dart';
import 'codec.dart';
import 'text_codec.dart';

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

class GenericTypeCodec extends Codec {
  final int oid;

  GenericTypeCodec(
    this.oid, {
    super.encodesNull,
    super.decodesNull,
  });

  @override
  EncodedValue encode(Object? value, CodecContext context) {
    final encoder = PostgresBinaryEncoder(oid);
    final bytes = encoder.convert(value, context.encoding);
    return EncodedValue.binary(bytes);
  }

  @override
  Object? decode(EncodedValue input, CodecContext context) {
    if (input.isBinary) {
      return PostgresBinaryDecoder.convert(context, oid, input.bytes!);
    } else {
      return PostgresTextDecoder.convert(context, oid, input.bytes!);
    }
  }
}
