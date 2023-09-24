import 'dart:convert';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

class PgByteDataWriter extends ByteDataWriter {
  final Encoding _encoding;

  PgByteDataWriter({
    super.bufferLength,
    Encoding encoding = utf8,
  }) : _encoding = encoding;

  late final encodingName = encodeString(_encoding.name);

  Uint8List encodeString(String value) {
    return castBytes(_encoding.encode(value));
  }

  void writeEncodedString(Uint8List value) {
    write(value);
    writeInt8(0);
  }

  void writeLengthEncodedString(String value) {
    final encoded = encodeString(value);
    writeUint32(5 + value.length);
    write(encoded);
    writeInt8(0);
  }
}
