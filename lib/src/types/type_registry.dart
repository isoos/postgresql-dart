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
  TypeOid.character: GenericTypeCodec(TypeOid.character),
  TypeOid.name: GenericTypeCodec(TypeOid.name),
  TypeOid.text: GenericTypeCodec(TypeOid.text),
  TypeOid.varChar: GenericTypeCodec(TypeOid.varChar),
  TypeOid.integer: GenericTypeCodec(TypeOid.integer),
  TypeOid.smallInteger: GenericTypeCodec(TypeOid.smallInteger),
  TypeOid.bigInteger: GenericTypeCodec(TypeOid.bigInteger),
  TypeOid.real: GenericTypeCodec(TypeOid.real),
  TypeOid.double: GenericTypeCodec(TypeOid.double),
  TypeOid.boolean: GenericTypeCodec(TypeOid.boolean),
  TypeOid.voidType: GenericTypeCodec(TypeOid.voidType),
  TypeOid.time: GenericTypeCodec(TypeOid.time),
  TypeOid.timestampWithTimezone:
      GenericTypeCodec(TypeOid.timestampWithTimezone),
  TypeOid.timestampWithoutTimezone:
      GenericTypeCodec(TypeOid.timestampWithoutTimezone),
  TypeOid.interval: GenericTypeCodec(TypeOid.interval),
  TypeOid.numeric: GenericTypeCodec(TypeOid.numeric),
  TypeOid.byteArray: GenericTypeCodec(TypeOid.byteArray),
  TypeOid.date: GenericTypeCodec(TypeOid.date),
  TypeOid.json: GenericTypeCodec(TypeOid.json, encodesNull: true),
  TypeOid.jsonb: GenericTypeCodec(TypeOid.jsonb, encodesNull: true),
  TypeOid.uuid: GenericTypeCodec(TypeOid.uuid),
  TypeOid.point: GenericTypeCodec(TypeOid.point),
  TypeOid.line: GenericTypeCodec(TypeOid.line),
  TypeOid.lineSegment: GenericTypeCodec(TypeOid.lineSegment),
  TypeOid.box: GenericTypeCodec(TypeOid.box),
  TypeOid.polygon: GenericTypeCodec(TypeOid.polygon),
  TypeOid.path: GenericTypeCodec(TypeOid.path),
  TypeOid.circle: GenericTypeCodec(TypeOid.circle),
  TypeOid.booleanArray: GenericTypeCodec(TypeOid.booleanArray),
  TypeOid.smallIntegerArray: GenericTypeCodec(TypeOid.smallIntegerArray),
  TypeOid.integerArray: GenericTypeCodec(TypeOid.integerArray),
  TypeOid.bigIntegerArray: GenericTypeCodec(TypeOid.bigIntegerArray),
  TypeOid.textArray: GenericTypeCodec(TypeOid.textArray),
  TypeOid.doubleArray: GenericTypeCodec(TypeOid.doubleArray),
  TypeOid.dateArray: GenericTypeCodec(TypeOid.dateArray),
  TypeOid.timeArray: GenericTypeCodec(TypeOid.timeArray),
  TypeOid.timestampArray: GenericTypeCodec(TypeOid.timestampArray),
  TypeOid.timestampTzArray: GenericTypeCodec(TypeOid.timestampTzArray),
  TypeOid.uuidArray: GenericTypeCodec(TypeOid.uuidArray),
  TypeOid.varCharArray: GenericTypeCodec(TypeOid.varCharArray),
  TypeOid.jsonbArray: GenericTypeCodec(TypeOid.jsonbArray),
  TypeOid.regtype: GenericTypeCodec(TypeOid.regtype),
  TypeOid.integerRange: GenericTypeCodec(TypeOid.integerRange),
  TypeOid.bigIntegerRange: GenericTypeCodec(TypeOid.bigIntegerRange),
  TypeOid.dateRange: GenericTypeCodec(TypeOid.dateRange),
  // TypeOid.numrange: GenericTypeCodec(TypeOid.numrange),
  TypeOid.timestampRange: GenericTypeCodec(TypeOid.timestampRange),
  TypeOid.timestampTzRange: GenericTypeCodec(TypeOid.timestampTzRange),
  TypeOid.tsvector: TsVectorTypeCodec(),
  TypeOid.tsquery: TsQueryTypeCodec(),
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
  'read': Type.real,
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

class TypeRegistry {
  final _byTypeOid = <int, Type>{};
  final _bySubstitutionName = <String, Type>{};
  final _codecs = <int, Codec>{};
  final _encoders = <EncoderFn>[];

  TypeRegistry({
    /// Override or extend the built-in codecs using the type OID as key.
    Map<int, Codec>? codecs,

    /// When encoding an untyped parameter for a query, try to use these encoders
    /// before the built-in (generic) text encoders.
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
}

final _textEncoder = const PostgresTextEncoder();

extension TypeRegistryExt on TypeRegistry {
  Type resolveOid(int oid) {
    return _byTypeOid[oid] ?? UnknownType(oid);
  }

  Type? resolveSubstitution(String name) => _bySubstitutionName[name];

  EncodedValue? encodeValue({
    required CodecContext context,
    required TypedValue typedValue,
  }) {
    final type = typedValue.type;
    final value = typedValue.value;
    final oid = type.oid;
    final codec = oid == null ? null : _codecs[oid];
    if (codec != null) {
      if (!codec.encodesNull && value == null) {
        return null;
      }
      return codec.encode(value, context);
    } else {
      for (final encoder in _encoders) {
        final encoded = encoder(value, context);
        if (encoded != null) {
          return encoded;
        }
      }
    }
    throw PgException("Could not infer type of value '$value'.");
  }

  Object? decodeBytes({
    required int typeOid,
    required EncodedValue value,
    required CodecContext context,
  }) {
    final codec = _codecs[typeOid];
    final bytes = value.bytes;
    if (codec != null) {
      if (!codec.decodesNull && bytes == null) {
        return null;
      }
      return codec.decode(value, context);
    } else {
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
}

EncodedValue? _defaultTextEncoder(Object? input, CodecContext context) {
  final encoded = _textEncoder.tryConvert(input);
  if (encoded != null) {
    return EncodedValue.text(castBytes(context.encoding.encode(encoded)));
  } else {
    return null;
  }
}
