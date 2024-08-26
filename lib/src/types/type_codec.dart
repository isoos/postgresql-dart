import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../buffer.dart';
import 'type_registry.dart';

/// Encodes the [input] value and returns an [EncodedValue] object.
///
/// May return `null` if the codec is not able to encode the [input].
typedef TypeEncoderFn = FutureOr<EncodedValue?> Function(
    TypeCodecContext context, Object? input);

/// Encoder and decoder for a given type (OID).
abstract class TypeCodec {
  /// Whether the `null` value is handled as a special case by this codec.
  ///
  /// By default Dart `null` values are encoded as SQL `NULL` values, and
  /// [TypeCodec] will not recieve the `null` value on its [encode] method.
  ///
  /// When the flag is set (`true`) the [TypeCodec.encode] will recieve `null`
  /// as `input` value.
  final bool encodesNull;

  /// Whether the SQL `NULL` value is handled as a special case by this codec.
  ///
  /// By default SQL `NULL` values are decoded as Dart `null` values, and
  /// [TypeCodec] will not recieve the `null` value on its [decode] method.
  ///
  /// When the flag is set (`true`) the [TypeCodec.decode] will recieve `null`
  /// as `input` value ([EncodedValue.bytes] will be `null`).
  final bool decodesNull;

  TypeCodec({
    this.encodesNull = false,
    this.decodesNull = false,
  });

  /// Encodes the [input] value and returns an [EncodedValue] object.
  ///
  /// May return `null` if the codec is not able to encode the [input].
  FutureOr<EncodedValue?> encode(TypeCodecContext context, Object? input);

  /// Decodes the [input] value and returns a Dart value object.
  ///
  /// May return [UndecodedBytes] if the codec is not able to decode the [input].
  FutureOr<Object?> decode(TypeCodecContext context, EncodedValue input);
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

class EncodedValue {
  final Uint8List? bytes;
  final bool isBinary;

  EncodedValue({
    required this.bytes,
    required this.isBinary,
  });
}
