import 'dart:convert';

import 'package:buffer/buffer.dart';

/// This class doesn't add much over using `List<int>` instead, however,
/// it creates a nice explicit type difference from both `String` and `List<int>`,
/// and it allows better use for the string encoding that delimits the value with `0`.
class EncodedString {
  final List<int> _bytes;
  EncodedString._(this._bytes);

  int get bytesLength => _bytes.length;
}

class PgByteDataWriter extends ByteDataWriter {
  final Encoding _encoding;

  PgByteDataWriter({
    super.bufferLength,
    Encoding encoding = utf8,
  }) : _encoding = encoding;

  late final encodingName = encodeString(_encoding.name);

  EncodedString encodeString(String value) {
    return EncodedString._(_encoding.encode(value));
  }

  void writeEncodedString(EncodedString value) {
    write(value._bytes);
    writeInt8(0);
  }

  void writeLengthEncodedString(String value) {
    final encoded = encodeString(value);
    writeUint32(5 + encoded.bytesLength);
    write(encoded._bytes);
    writeInt8(0);
  }
}
