import 'dart:convert';

import 'package:buffer/buffer.dart';
import 'package:postgres/src/types/type_codec.dart';

/// This class doesn't add much over using `List<int>` instead, however,
/// it creates a nice explicit type difference from both `String` and `List<int>`,
/// and it allows better use for the string encoding that delimits the value with `0`.
class EncodedString {
  final List<int> _bytes;
  EncodedString._(this._bytes);

  int get bytesLength => _bytes.length;
}

class PgByteDataWriter extends ByteDataWriter {
  final Encoding encoding;

  PgByteDataWriter({
    super.bufferLength,
    required this.encoding,
  });

  late final encodingName = encodeString(encoding.name);

  EncodedString encodeString(String value) {
    return EncodedString._(encoding.encode(value));
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

const _emptyString = '';

class PgByteDataReader extends ByteDataReader {
  final CodecContext codecContext;

  PgByteDataReader({
    required this.codecContext,
  });

  Encoding get encoding => codecContext.encoding;

  String readNullTerminatedString() {
    final bytes = readUntilTerminatingByte(0);
    if (bytes.isEmpty) {
      return _emptyString;
    }
    return codecContext.encoding.decode(bytes);
  }
}
