import 'dart:convert';

import 'package:buffer/buffer.dart';

// Old UTF8BackedString utf8_backed_string.dart
class EncodedString {
  EncodedString(this.string, this.encoding);

  List<int>? _cachedUTF8Bytes;

  bool get hasCachedBytes => _cachedUTF8Bytes != null;

  final String string;
  final Encoding encoding;
  // old utf8Length
  int get byteLength {
    _cachedUTF8Bytes ??= encoding.encode(string);
    return _cachedUTF8Bytes!.length;
  }
  // old utf8Bytes
  List<int> get encodedBytes {
    _cachedUTF8Bytes ??= encoding.encode(string);
    return _cachedUTF8Bytes!;
  }

  void applyToBuffer(ByteDataWriter buffer) {
    buffer.write(encodedBytes);
    buffer.writeInt8(0);
  }
}
