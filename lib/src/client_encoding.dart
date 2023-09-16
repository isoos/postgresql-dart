import 'dart:convert' as c;
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

/// Describes the client encoding used by a connection.
class ClientEncoding {
  /// The Dart [Encoding] object.
  final c.Encoding encoding;

  ClientEncoding(this.encoding);

  static final utf8 = ClientEncoding(c.utf8);

  /// The optimized (fused encoding to/from JSON and bytes)
  late final _jsonEncoding = c.json.fuse(encoding);

  Uint8List encodeString(String input) => castBytes(encoding.encode(input));
  Uint8List encodeJson(Object? input) => castBytes(_jsonEncoding.encode(input));

  String decodeString(List<int> encoded) => encoding.decode(encoded);
  Object? decodeJson(List<int> encoded) => _jsonEncoding.decode(encoded);
}
