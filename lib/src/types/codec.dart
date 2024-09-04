import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:postgres/src/v3/relation_tracker.dart';

import '../buffer.dart';
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
  Object? input,
  CodecContext context,
);

/// Encoder and decoder for a value stored in Postgresql.
abstract class Codec {
  /// Whether the `null` value is handled as a special case by this codec.
  ///
  /// By default Dart `null` values are encoded as SQL `NULL` values, and
  /// [Codec] will not recieve the `null` value on its [encode] method.
  ///
  /// When the flag is set (`true`) the [Codec.encode] will recieve `null`
  /// as `input` value.
  final bool encodesNull;

  /// Whether the SQL `NULL` value is handled as a special case by this codec.
  ///
  /// By default SQL `NULL` values are decoded as Dart `null` values, and
  /// [Codec] will not recieve the `null` value on its [decode] method.
  ///
  /// When the flag is set (`true`) the [Codec.decode] will recieve `null`
  /// as `input` value ([EncodedValue.bytes] will be `null`).
  final bool decodesNull;

  Codec({
    this.encodesNull = false,
    this.decodesNull = false,
  });

  /// Encodes the [input] value and returns an [EncodedValue] object.
  ///
  /// May return `null` if the codec is not able to encode the [input].
  EncodedValue? encode(Object? input, CodecContext context);

  /// Decodes the [input] value and returns a Dart value object.
  ///
  /// May return [UndecodedBytes] if the codec is not able to decode the [input].
  Object? decode(EncodedValue input, CodecContext context);
}

/// Provides access to connection and database information, and also to additional codecs.
class CodecContext {
  final Encoding encoding;
  final RelationTracker relationTracker;
  final RuntimeParameters runtimeParameters;
  final TypeRegistry typeRegistry;

  CodecContext({
    required this.encoding,
    required this.relationTracker,
    required this.runtimeParameters,
    required this.typeRegistry,
  });

  factory CodecContext.withDefaults({
    Encoding? encoding,
    RelationTracker? relationTracker,
    RuntimeParameters? runtimeParameters,
    TypeRegistry? typeRegistry,
  }) {
    return CodecContext(
      encoding: encoding ?? utf8,
      relationTracker: relationTracker ?? RelationTracker(),
      runtimeParameters: runtimeParameters ?? RuntimeParameters(),
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

/// The read-only, passive view of the Postgresql's runtime/session parameters.
///
/// Postgresql server reports certain parameter values at opening a connection
/// or whenever their values change. Such parameters may include:
/// - `application_name`
/// - `server_version`
/// - `server_encoding`
/// - `client_encoding`
/// - `is_superuser`
/// - `session_authorization`
/// - `DateStyle`
/// - `TimeZone`
/// - `integer_datetimes`
///
/// This class holds the latest parameter values send by the server.
/// The values are not queried or updated actively.
///
/// The available parameters may be discovered following the instructions on these URLs:
/// - https://www.postgresql.org/docs/current/sql-show.html
/// - https://www.postgresql.org/docs/current/runtime-config.html
/// - https://www.postgresql.org/docs/current/libpq-status.html#LIBPQ-PQPARAMETERSTATUS
class RuntimeParameters {
  final _values = <String, String>{};

  RuntimeParameters({Map<String, String>? initialValues}) {
    if (initialValues != null) {
      _values.addAll(initialValues);
    }
  }

  /// The latest values of the runtime parameters. The map is read-only.
  late final latestValues = UnmodifiableMapView(_values);

  String? get applicationName => latestValues['application_name'];
}

extension RuntimeParametersExt on RuntimeParameters {
  void setValue(String name, String value) {
    _values[name] = value;
  }
}
