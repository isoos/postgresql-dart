import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:postgres/src/v3/relation_tracker.dart';

import '../buffer.dart';
import 'type_registry.dart';

/// Encodes the [input] value and returns an [EncodedValue] object.
///
/// May return `null` if the codec is not able to encode the [input].
typedef TypeEncoderFn = EncodedValue? Function(
    TypeCodecContext context, Object? input);

/// Encoder and decoder for a given type (OID).
abstract class TypeCodec {
  /// Whether the `null` value is handled as a special case by this codec.
  ///
  /// By default Dart `null` values are encoded as SQL `NULL` values, and
  /// [TypeCodec] will not recieve the `null` value on its [encode] method.
  ///
  /// When the flag is set (`true`) the [TypeCodec.encode] will recieve `null`
  /// as `input` value.
  final bool encodesNull;

  /// Whether the SQL `NULL` value is handled as a special case by this codec.
  ///
  /// By default SQL `NULL` values are decoded as Dart `null` values, and
  /// [TypeCodec] will not recieve the `null` value on its [decode] method.
  ///
  /// When the flag is set (`true`) the [TypeCodec.decode] will recieve `null`
  /// as `input` value ([EncodedValue.bytes] will be `null`).
  final bool decodesNull;

  TypeCodec({
    this.encodesNull = false,
    this.decodesNull = false,
  });

  /// Encodes the [input] value and returns an [EncodedValue] object.
  ///
  /// May return `null` if the codec is not able to encode the [input].
  EncodedValue? encode(TypeCodecContext context, Object? input);

  /// Decodes the [input] value and returns a Dart value object.
  ///
  /// May return [UndecodedBytes] if the codec is not able to decode the [input].
  Object? decode(TypeCodecContext context, EncodedValue input);
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

class TypeCodecContext {
  final Encoding encoding;
  final RelationTracker relationTracker;
  final RuntimeParameters runtimeParameters;
  final TypeRegistry typeRegistry;

  TypeCodecContext({
    required this.encoding,
    required this.relationTracker,
    required this.runtimeParameters,
    required this.typeRegistry,
  });

  PgByteDataReader newPgByteDataReader([Uint8List? bytes]) {
    final reader = PgByteDataReader(encoding: encoding);
    if (bytes != null) {
      reader.add(bytes);
    }
    return reader;
  }

  PgByteDataWriter newPgByteDataWriter() {
    return PgByteDataWriter(encoding: encoding);
  }
}

class EncodedValue {
  final Uint8List? bytes;
  final bool isBinary;

  EncodedValue({
    required this.bytes,
    required this.isBinary,
  });
}
