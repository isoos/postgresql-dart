import 'dart:convert';
import 'dart:typed_data';

import 'package:postgres/src/timezone_settings.dart';

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

class EncodeInput<T> {
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
  final TimeZoneSettings timeZone;

  DecodeInput({
    required this.bytes,
    required this.isBinary,
    required this.encoding,
    required this.timeZone,
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
  const GenericType(super.oid);
}

extension GenericTypeExt<T extends Object> on GenericType<T> {
  EncodeOutput encode(EncodeInput<T?> input) {
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
