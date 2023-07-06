import 'dart:convert';

import 'package:buffer/buffer.dart';

class UTF8BackedString {
  UTF8BackedString(this.string, this.encoding);

  List<int>? _cachedUTF8Bytes;

  bool get hasCachedBytes => _cachedUTF8Bytes != null;

  final String string;
  final Encoding encoding;
  

  int get utf8Length {
    _cachedUTF8Bytes ??= utf8.encode(string);
    return _cachedUTF8Bytes!.length;
  }

  List<int> get utf8Bytes {
    _cachedUTF8Bytes ??= utf8.encode(string);
    return _cachedUTF8Bytes!;
  }

  void applyToBuffer(ByteDataWriter buffer) {
    buffer.write(utf8Bytes);
    buffer.writeInt8(0);
  }
}
