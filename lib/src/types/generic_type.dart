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

class GenericCodec extends Codec {
  final int oid;

  /// Whether the `null` value is handled as a special case by this codec.
  ///
  /// By default Dart `null` values are encoded as SQL `NULL` values, and
  /// [Codec] will not recieve the `null` value on its [encode] method.
  ///
  /// When the flag is set (`true`) the [Codec.encode] will recieve `null`
  /// as `input` value.
  final bool encodesNull;

  GenericCodec(
    this.oid, {
    this.encodesNull = false,
  });

  @override
  EncodedValue? encode(TypedValue input, CodecContext context) {
    final value = input.value;
    if (!encodesNull && value == null) {
      return null;
    }
    final encoder = PostgresBinaryEncoder(oid);
    final bytes = encoder.convert(value, context.encoding);
    return EncodedValue.binary(bytes);
  }

  @override
  Object? decode(EncodedValue input, CodecContext context) {
    final bytes = input.bytes;
    if (bytes == null) {
      return null;
    }
    if (input.isBinary) {
      return PostgresBinaryDecoder.convert(context, oid, bytes);
    } else {
      return PostgresTextDecoder.convert(context, oid, bytes);
    }
  }
}
