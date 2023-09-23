import 'dart:convert';

import 'package:buffer/buffer.dart';

class EncodedString {
  final List<int> _bytes;
  EncodedString.fromValue(String value, {Encoding encoding = utf8})
      : _bytes = encoding.encode(value);

  int get bytesLength => _bytes.length;
}

class PgByteDataWriter extends ByteDataWriter {
  final Encoding _encoding;

  PgByteDataWriter({
    super.bufferLength,
    Encoding encoding = utf8,
  }) : _encoding = encoding;

  late final encodingName = prepareString(_encoding.name);

  EncodedString prepareString(String value) {
    return EncodedString.fromValue(value, encoding: _encoding);
  }

  void writeEncodedString(EncodedString value) {
    write(value._bytes);
    writeInt8(0);
  }

  void writeLengthEncodedString(String value) {
    final encoded = EncodedString.fromValue(value, encoding: _encoding);
    writeUint32(5 + encoded.bytesLength);
    write(encoded._bytes);
    writeInt8(0);
  }
}
