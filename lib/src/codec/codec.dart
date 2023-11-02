import 'dart:convert';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import '../types.dart';
import 'binary_codec.dart';
import 'text_codec.dart';

abstract class CustomCodec {
  bool canDecode(DecodeInput input);
  Object? decode(DecodeInput input);

  bool canEncode(Object value);
  Uint8List? encode(Object? value);
}

class DecodeInput {
  final int typeOid;
  final bool isBinaryEncoding;
  final Uint8List? bytes;

  DecodeInput({
    required this.typeOid,
    required this.isBinaryEncoding,
    required this.bytes,
  });
}

class TypeCodec {
  final Encoding encoding;
  final List<CustomCodec>? customCodecs;

  TypeCodec({
    required this.encoding,
    this.customCodecs,
  });

  Object? decode(DecodeInput input) {
    final type = Type.byTypeOid[input.typeOid] ?? Type.unknownType;
    if (type == Type.unknownType && customCodecs != null) {
      for (final cc in customCodecs!) {
        if (cc.canDecode(input)) {
          return cc.decode(input);
        }
      }
    }
    if (input.isBinaryEncoding) {
      return PostgresBinaryDecoder(type).convert(input.bytes, encoding);
    } else {
      return PostgresTextDecoder(type).convert(input.bytes, encoding);
    }
  }

  Uint8List? encode(Type type, Object? value) {
    if (type != Type.unspecified) {
      return PostgresBinaryEncoder(type).convert(value, encoding);
    }
    if (value != null) {
      return castBytes(encoding
          .encode(PostgresTextEncoder().convert(value, escapeStrings: false)));
    }
    return null;
  }
}
