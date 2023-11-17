import 'dart:convert';
import 'dart:typed_data';

import '../types.dart';
import 'binary_codec.dart';
import 'text_codec.dart';
import 'type_registry.dart';

class EncodeOutput {
  final Uint8List? bytes;
  final String? text;

  EncodeOutput.bytes(Uint8List value)
      : bytes = value,
        text = null;

  EncodeOutput.text(String value)
      : bytes = null,
        text = value;

  bool get isBinary => bytes != null;
}

class EncodeInput<T extends Object> {
  final T value;
  final Encoding encoding;

  EncodeInput({
    required this.value,
    required this.encoding,
  });
}

class DecodeInput {
  final Uint8List bytes;
  final bool isBinary;
  final Encoding encoding;
  final TypeRegistry typeRegistry;

  DecodeInput({
    required this.bytes,
    required this.isBinary,
    required this.encoding,
    required this.typeRegistry,
  });

  late final asText = encoding.decode(bytes);
}

class UnknownType extends Type<Object> {
  const UnknownType(super.oid);
}

class UnspecifiedType extends Type<Object> {
  const UnspecifiedType() : super(null);
}

/// NOTE: do not use this type in client code.
class GenericType<T extends Object> extends Type<T> {
  /// The name of this type as considered by [Sql].
  ///
  /// To declare an explicit type for a substituted parameter in a query, this
  /// name can be used.
  final List<String>? _typeNames;

  const GenericType(
    super.oid, {
    List<String>? typeNames,
  }) : _typeNames = typeNames;
}

extension GenericTypeExt<T extends Object> on GenericType<T> {
  List<String>? get typeNames => _typeNames;

  EncodeOutput encode(EncodeInput input) {
    if (oid != null && oid! > 0) {
      final encoder = PostgresBinaryEncoder(oid!);
      final bytes = encoder.convert(input.value, input.encoding);
      return EncodeOutput.bytes(bytes);
    } else {
      const converter = PostgresTextEncoder();
      final text = converter.convert(input.value, escapeStrings: false);
      return EncodeOutput.text(text);
    }
  }

  T? decode(DecodeInput input) {
    if (input.isBinary) {
      return PostgresBinaryDecoder(oid!).convert(input) as T?;
    } else {
      return PostgresTextDecoder(oid!).convert(input) as T?;
    }
  }
}
