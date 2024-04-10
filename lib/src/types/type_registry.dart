import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../exceptions.dart';
import '../types.dart';
import 'generic_type.dart';
import 'text_codec.dart';
import 'text_search.dart';

typedef TypeEncoderFn = EncodeOutput Function(EncodeInput input);
typedef TypeDecoderFn = Object? Function(DecodeInput input);

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

  TypeRegistry() {
    for (final t in _builtInTypes) {
      _register(t);
    }
  }

  /// Registers a type.
  void _register(Type type) {
    _bySubstitutionName.addAll(_builtInTypeNames);
    if (type.oid != null && type.oid! > 0) {
      _byTypeOid[type.oid!] = type;
    }
  }
}

final _textEncoder = const PostgresTextEncoder();

extension TypeRegistryExt on TypeRegistry {
  String? lookupTypeName(Type type) {
    return _bySubstitutionName.entries
        .firstWhereOrNull((e) => e.value == type)
        ?.key;
  }

  Type resolveOid(int oid) {
    return _byTypeOid[oid] ?? UnknownType(oid);
  }

  Type? resolveSubstitution(String name) => _bySubstitutionName[name];

  /// Note: this returns only types with oids.
  @internal
  Iterable<Type> get registered => _byTypeOid.values;

  EncodeOutput? encodeValue(
    Object? value, {
    required Type type,
    required Encoding encoding,
    required bool isSqlNull,
  }) {
    if (isSqlNull) {
      return null;
    }

    switch (type) {
      case GenericType():
        return type.encode(EncodeInput(value: value, encoding: encoding));
      case TsVectorType():
        return type.encode(EncodeInput(value: value, encoding: encoding));
      case TsQueryType():
        return type.encode(EncodeInput(value: value, encoding: encoding));
      case UnspecifiedType():
        final encoded = _textEncoder.tryConvert(value);
        if (encoded != null) {
          return EncodeOutput.text(encoded);
        }
        break;
    }
    throw PgException("Could not infer type of value '$value'.");
  }

  Object? decodeBytes(
    Uint8List? bytes, {
    required int typeOid,
    required bool isBinary,
    required Encoding encoding,
  }) {
    if (bytes == null) {
      return null;
    }
    final type = resolveOid(typeOid);
    switch (type) {
      case GenericType():
        return type.decode(DecodeInput(
          bytes: bytes,
          isBinary: isBinary,
          encoding: encoding,
          typeRegistry: this,
        ));
      case TsVectorType():
        return type.decode(DecodeInput(
          bytes: bytes,
          isBinary: isBinary,
          encoding: encoding,
          typeRegistry: this,
        ));
      case TsQueryType():
        return type.decode(DecodeInput(
          bytes: bytes,
          isBinary: isBinary,
          encoding: encoding,
          typeRegistry: this,
        ));
      case UnknownType():
        return UndecodedBytes(
          typeOid: typeOid,
          bytes: bytes,
          isBinary: isBinary,
          encoding: encoding,
        );
    }
    return UndecodedBytes(
      typeOid: typeOid,
      bytes: bytes,
      isBinary: isBinary,
      encoding: encoding,
    );
  }
}
