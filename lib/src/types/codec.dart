import 'dart:convert';
import 'dart:typed_data';

import '../buffer.dart';
import '../types.dart';
import '../v3/connection_info.dart';
import '../v3/database_info.dart';
import 'type_registry.dart';

/// Represents the [bytes] of a received (field) or sent (parameter) value.
///
/// The [format] describes whether the [bytes] are formatted as text (e.g. `12`)
/// or bytes (e.g. `0x0c`).
class EncodedValue {
  /// The encoded bytes of the value.
  final Uint8List? bytes;

  /// The format of the [bytes].
  final EncodingFormat format;

  /// The type OID - if available.
  final int? typeOid;

  EncodedValue(
    this.bytes, {
    required this.format,
    this.typeOid,
  });

  EncodedValue.binary(
    this.bytes, {
    this.typeOid,
  }) : format = EncodingFormat.binary;

  EncodedValue.text(
    this.bytes, {
    this.typeOid,
  }) : format = EncodingFormat.text;

  EncodedValue.null$({
    this.format = EncodingFormat.binary,
    this.typeOid,
  }) : bytes = null;

  bool get isBinary => format == EncodingFormat.binary;
  bool get isText => format == EncodingFormat.text;
}

/// Describes whether the bytes are formatted as [text] (e.g. `12`) or
/// [binary] (e.g. `0x0c`)
enum EncodingFormat {
  binary,
  text,
  ;

  static EncodingFormat fromBinaryFlag(bool isBinary) =>
      isBinary ? binary : text;
}

/// Encodes the [input] value and returns an [EncodedValue] object.
///
/// May return `null` if the encoder is not able to convert the [input] value.
typedef EncoderFn = EncodedValue? Function(
    TypedValue input, CodecContext context);

/// Encoder and decoder for a value stored in Postgresql.
abstract class Codec {
  /// Encodes the [input] value and returns an [EncodedValue] object.
  ///
  /// May return `null` if the codec is not able to encode the [input].
  EncodedValue? encode(TypedValue input, CodecContext context);

  /// Decodes the [input] value and returns a Dart value object.
  ///
  /// May return [UndecodedBytes] or the same [input] instance if the codec
  /// is not able to decode the [input].
  Object? decode(EncodedValue input, CodecContext context);
}

/// Provides access to connection and database information, and also to additional codecs.
class CodecContext {
  final ConnectionInfo connectionInfo;
  final DatabaseInfo databaseInfo;
  final Encoding encoding;
  final TypeRegistry typeRegistry;

  CodecContext({
    required this.connectionInfo,
    required this.databaseInfo,
    required this.encoding,
    required this.typeRegistry,
  });

  factory CodecContext.withDefaults({
    ConnectionInfo? connectionInfo,
    DatabaseInfo? databaseInfo,
    Encoding? encoding,
    TypeRegistry? typeRegistry,
  }) {
    return CodecContext(
      connectionInfo: connectionInfo ?? ConnectionInfo(),
      databaseInfo: databaseInfo ?? DatabaseInfo(),
      encoding: encoding ?? utf8,
      typeRegistry: typeRegistry ?? TypeRegistry(),
    );
  }

  PgByteDataReader newPgByteDataReader([Uint8List? bytes]) {
    final reader = PgByteDataReader(codecContext: this);
    if (bytes != null) {
      reader.add(bytes);
    }
    return reader;
  }

  PgByteDataWriter newPgByteDataWriter() {
    return PgByteDataWriter(encoding: encoding);
  }
}
