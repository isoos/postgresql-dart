import 'dart:convert';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import '../postgres.dart';

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
  final TypeCodec _codec;

  PgByteDataWriter({
    super.bufferLength,
    required this.encoding,
    TypeCodec? codec,
  }) : _codec = codec ?? TypeCodec(encoding: encoding);

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

  Uint8List? encodeTypedValue(TypedValue value) {
    return _codec.encode(value.type, value.value);
  }
}

const _emptyString = '';

class PgByteDataReader extends ByteDataReader {
  final Encoding encoding;

  PgByteDataReader({
    required this.encoding,
  });

  String readNullTerminatedString() {
    final bytes = readUntilTerminatingByte(0);
    if (bytes.isEmpty) {
      return _emptyString;
    }
    return encoding.decode(bytes);
  }
}
