import 'package:buffer/buffer.dart';

import '../exceptions.dart';
import '../types.dart';
import 'codec.dart';
import 'generic_type.dart';
import 'text_codec.dart';
import 'text_search.dart';

/// See: https://github.com/postgres/postgres/blob/master/src/include/catalog/pg_type.dat
class TypeOid {
  static const bigInteger = 20;
  static const bigIntegerArray = 1016;
  static const bigIntegerRange = 3926;
  static const boolean = 16;
  static const booleanArray = 1000;
  static const box = 603;
  static const byteArray = 17;
  static const character = 1042;
  static const circle = 718;
  static const date = 1082;
  static const dateArray = 1182;
  static const dateRange = 3912;
  static const double = 701;
  static const doubleArray = 1022;
  static const integer = 23;
  static const integerArray = 1007;
  static const integerRange = 3904;
  static const interval = 1186;
  static const json = 114;
  static const jsonb = 3802;
  static const jsonbArray = 3807;
  static const line = 628;
  static const lineSegment = 601;
  static const name = 19;
  static const numeric = 1700;
  static const numericRange = 3906;
  static const path = 602;
  static const point = 600;
  static const polygon = 604;
  static const real = 700;
  static const regtype = 2206;
  static const smallInteger = 21;
  static const smallIntegerArray = 1005;
  static const text = 25;
  static const textArray = 1009;
  static const time = 1083;
  static const timeArray = 1183;
  static const timestamp = 1114;
  static const timestampArray = 1115;
  static const timestampRange = 3908;

  /// Please use [TypeOid.timestamp] instead.
  static const timestampWithoutTimezone = timestamp;
  static const timestampTz = 1184;
  static const timestampTzArray = 1185;
  static const timestampTzRange = 3910;

  /// Please use [TypeOid.timestampTz] instead.
  static const timestampWithTimezone = timestampTz;
  static const tsquery = 3615;
  static const tsvector = 3614;
  static const uuid = 2950;
  static const uuidArray = 2951;
  static const varChar = 1043;
  static const varCharArray = 1015;
  static const voidType = 2278;
}

final _builtInTypes = <Type>{
  Type.unspecified,
  Type.character,
  Type.name,
  Type.text,
  Type.varChar,
  Type.integer,
  Type.smallInteger,
  Type.bigInteger,
  Type.real,
  Type.double,
  Type.boolean,
  Type.voidType,
  Type.time,
  Type.timestampWithTimezone,
  Type.timestampWithoutTimezone,
  Type.interval,
  Type.numeric,
  Type.byteArray,
  Type.date,
  Type.json,
  Type.jsonb,
  Type.uuid,
  Type.point,
  Type.line,
  Type.lineSegment,
  Type.box,
  Type.polygon,
  Type.path,
  Type.circle,
  Type.booleanArray,
  Type.smallIntegerArray,
  Type.integerArray,
  Type.bigIntegerArray,
  Type.textArray,
  Type.doubleArray,
  Type.dateArray,
  Type.timeArray,
  Type.timestampArray,
  Type.timestampTzArray,
  Type.uuidArray,
  Type.varCharArray,
  Type.jsonbArray,
  Type.regtype,
  Type.integerRange,
  Type.bigIntegerRange,
  Type.dateRange,
  // Type.numrange,
  Type.timestampRange,
  Type.timestampTzRange,
  Type.tsvector,
  Type.tsquery,
};

final _builtInCodecs = <int, Codec>{
  TypeOid.character: GenericCodec(TypeOid.character),
  TypeOid.name: GenericCodec(TypeOid.name),
  TypeOid.text: GenericCodec(TypeOid.text),
  TypeOid.varChar: GenericCodec(TypeOid.varChar),
  TypeOid.integer: GenericCodec(TypeOid.integer),
  TypeOid.smallInteger: GenericCodec(TypeOid.smallInteger),
  TypeOid.bigInteger: GenericCodec(TypeOid.bigInteger),
  TypeOid.real: GenericCodec(TypeOid.real),
  TypeOid.double: GenericCodec(TypeOid.double),
  TypeOid.boolean: GenericCodec(TypeOid.boolean),
  TypeOid.voidType: GenericCodec(TypeOid.voidType),
  TypeOid.time: GenericCodec(TypeOid.time),
  TypeOid.timestampWithTimezone: GenericCodec(TypeOid.timestampWithTimezone),
  TypeOid.timestampWithoutTimezone:
      GenericCodec(TypeOid.timestampWithoutTimezone),
  TypeOid.interval: GenericCodec(TypeOid.interval),
  TypeOid.numeric: GenericCodec(TypeOid.numeric),
  TypeOid.byteArray: GenericCodec(TypeOid.byteArray),
  TypeOid.date: GenericCodec(TypeOid.date),
  TypeOid.json: GenericCodec(TypeOid.json, encodesNull: true),
  TypeOid.jsonb: GenericCodec(TypeOid.jsonb, encodesNull: true),
  TypeOid.uuid: GenericCodec(TypeOid.uuid),
  TypeOid.point: GenericCodec(TypeOid.point),
  TypeOid.line: GenericCodec(TypeOid.line),
  TypeOid.lineSegment: GenericCodec(TypeOid.lineSegment),
  TypeOid.box: GenericCodec(TypeOid.box),
  TypeOid.polygon: GenericCodec(TypeOid.polygon),
  TypeOid.path: GenericCodec(TypeOid.path),
  TypeOid.circle: GenericCodec(TypeOid.circle),
  TypeOid.booleanArray: GenericCodec(TypeOid.booleanArray),
  TypeOid.smallIntegerArray: GenericCodec(TypeOid.smallIntegerArray),
  TypeOid.integerArray: GenericCodec(TypeOid.integerArray),
  TypeOid.bigIntegerArray: GenericCodec(TypeOid.bigIntegerArray),
  TypeOid.textArray: GenericCodec(TypeOid.textArray),
  TypeOid.doubleArray: GenericCodec(TypeOid.doubleArray),
  TypeOid.dateArray: GenericCodec(TypeOid.dateArray),
  TypeOid.timeArray: GenericCodec(TypeOid.timeArray),
  TypeOid.timestampArray: GenericCodec(TypeOid.timestampArray),
  TypeOid.timestampTzArray: GenericCodec(TypeOid.timestampTzArray),
  TypeOid.uuidArray: GenericCodec(TypeOid.uuidArray),
  TypeOid.varCharArray: GenericCodec(TypeOid.varCharArray),
  TypeOid.jsonbArray: GenericCodec(TypeOid.jsonbArray),
  TypeOid.regtype: GenericCodec(TypeOid.regtype),
  TypeOid.integerRange: GenericCodec(TypeOid.integerRange),
  TypeOid.bigIntegerRange: GenericCodec(TypeOid.bigIntegerRange),
  TypeOid.dateRange: GenericCodec(TypeOid.dateRange),
  // TypeOid.numrange: GenericTypeCodec(TypeOid.numrange),
  TypeOid.timestampRange: GenericCodec(TypeOid.timestampRange),
  TypeOid.timestampTzRange: GenericCodec(TypeOid.timestampTzRange),
  TypeOid.tsvector: TsVectorCodec(),
  TypeOid.tsquery: TsQueryCodec(),
};

final _builtInTypeNames = <String, Type>{
  'bigint': Type.bigInteger,
  'boolean': Type.boolean,
  'bytea': Type.byteArray,
  'bpchar': Type.character,
  'char': Type.character,
  'character': Type.character,
  'date': Type.date,
  'daterange': Type.dateRange,
  'double precision': Type.double,
  'float4': Type.real,
  'float8': Type.double,
  'int': Type.integer,
  'int2': Type.smallInteger,
  'int4': Type.integer,
  'int4range': Type.integerRange,
  'int8': Type.bigInteger,
  'int8range': Type.bigIntegerRange,
  'integer': Type.integer,
  'interval': Type.interval,
  'json': Type.json,
  'jsonb': Type.jsonb,
  'name': Type.name,
  'numeric': Type.numeric,
  // 'numrange': Type.numrange,
  'point': Type.point,
  'line': Type.line,
  'lseg': Type.lineSegment,
  'box': Type.box,
  'polygon': Type.polygon,
  'path': Type.path,
  'circle': Type.circle,
  'real': Type.real,
  'regtype': Type.regtype,
  'serial4': Type.serial,
  'serial8': Type.bigSerial,
  'smallint': Type.smallInteger,
  'text': Type.text,
  'time': Type.time,
  'timestamp': Type.timestampWithoutTimezone,
  'timestamptz': Type.timestampWithTimezone,
  'tsrange': Type.timestampRange,
  'tstzrange': Type.timestampTzRange,
  'tsquery': Type.tsquery,
  'tsvector': Type.tsvector,
  'varchar': Type.varChar,
  'uuid': Type.uuid,
  '_bool': Type.booleanArray,
  '_date': Type.dateArray,
  '_float8': Type.doubleArray,
  '_int2': Type.smallIntegerArray,
  '_int4': Type.integerArray,
  '_int8': Type.bigIntegerArray,
  '_time': Type.timeArray,
  '_timestamp': Type.timestampArray,
  '_timestamptz': Type.timestampTzArray,
  '_jsonb': Type.jsonbArray,
  '_text': Type.textArray,
  '_uuid': Type.uuidArray,
  '_varchar': Type.varCharArray,
};

/// Contains the static registry of type mapping from substitution names to
/// type OIDs, their codec and the generic type encoders (for un-typed values).
class TypeRegistry {
  final _byTypeOid = <int, Type>{};
  final _bySubstitutionName = <String, Type>{};
  final _codecs = <int, Codec>{};
  final _encoders = <EncoderFn>[];

  TypeRegistry({
    /// Override or extend the built-in codecs using the type OID as key.
    Map<int, Codec>? codecs,

    /// When encoding a non-typed parameter for a query, try to use these
    /// encoders in their specified order. The encoders will be called
    /// before the the built-in (generic) text encoders.
    Iterable<EncoderFn>? encoders,
  }) {
    _bySubstitutionName.addAll(_builtInTypeNames);
    _codecs.addAll(_builtInCodecs);
    for (final type in _builtInTypes) {
      if (type.oid != null && type.oid! > 0) {
        _byTypeOid[type.oid!] = type;
      }
    }
    if (codecs != null) {
      _codecs.addAll(codecs);
    }
    _encoders.addAll([
      ...?encoders,
      _defaultTextEncoder,
    ]);
  }

  Future<EncodedValue?> encode(TypedValue input, CodecContext context) async {
    // check for codec
    final typeOid = input.type.oid;
    final codec = typeOid == null ? null : _codecs[typeOid];
    if (codec != null) {
      final r = await codec.encode(input, context);
      if (r != null) {
        return r;
      }
    }

    // fallback encoders
    for (final encoder in _encoders) {
      final encoded = await encoder(input, context);
      if (encoded != null) {
        return encoded;
      }
    }
    throw PgException("Could not infer type of value '${input.value}'.");
  }

  Future<Object?> decode(EncodedValue value, CodecContext context) async {
    final typeOid = value.typeOid;
    if (typeOid == null) {
      throw ArgumentError('`EncodedValue.typeOid` was not provided.');
    }

    // check for codec
    final codec = _codecs[typeOid];
    if (codec != null) {
      final r = await codec.decode(value, context);
      if (r != value && r is! UndecodedBytes) {
        return r;
      }
    }

    // fallback decoding
    final bytes = value.bytes;
    if (bytes == null) {
      return null;
    }
    return UndecodedBytes(
      typeOid: typeOid,
      bytes: bytes,
      isBinary: value.isBinary,
      encoding: context.encoding,
    );
  }
}

final _textEncoder = const PostgresTextEncoder();

extension TypeRegistryExt on TypeRegistry {
  Type resolveOid(int oid) {
    return _byTypeOid[oid] ?? UnknownType(oid);
  }

  Type? resolveSubstitution(String name) {
    if (name == 'read') {
      print(
          'WARNING: Use `real` instead of `read` - will be removed in a future release.');
      return Type.real;
    }
    return _bySubstitutionName[name];
  }
}

EncodedValue? _defaultTextEncoder(TypedValue input, CodecContext context) {
  final value = input.value;
  final encoded = _textEncoder.tryConvert(value);
  if (encoded != null) {
    return EncodedValue.text(castBytes(context.encoding.encode(encoded)));
  } else {
    return null;
  }
}
