import '../types.dart';

import 'generic_type.dart';

/// See: https://github.com/postgres/postgres/blob/master/src/include/catalog/pg_type.dat
class TypeOid {
  static const bigInteger = 20;
  static const bigIntegerArray = 1016;
  static const boolean = 16;
  static const booleanArray = 1000;
  static const byteArray = 17;
  static const date = 1082;
  static const double = 701;
  static const doubleArray = 1022;
  static const integer = 23;
  static const integerArray = 1007;
  static const interval = 1186;
  static const json = 114;
  static const jsonb = 3802;
  static const jsonbArray = 3807;
  static const name = 19;
  static const numeric = 1700;
  static const point = 600;
  static const real = 700;
  static const regtype = 2206;
  static const smallInteger = 21;
  static const text = 25;
  static const textArray = 1009;
  static const timestampWithoutTimezone = 1114;
  static const timestampWithTimezone = 1184;
  static const uuid = 2950;
  static const varChar = 1043;
  static const varCharArray = 1015;
  static const voidType = 2278;
}

class TypeRegistry {
  // TODO: implement connection-level registry
  static final instance = TypeRegistry();

  final values = <Type>{
    Type.unspecified,
    Type.name,
    Type.text,
    Type.varChar,
    Type.integer,
    Type.smallInteger,
    Type.bigInteger,
    Type.serial,
    Type.bigSerial,
    Type.real,
    Type.double,
    Type.boolean,
    Type.voidType,
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
    Type.booleanArray,
    Type.integerArray,
    Type.bigIntegerArray,
    Type.textArray,
    Type.doubleArray,
    Type.varCharArray,
    Type.jsonbArray,
    Type.regtype,
  };

  late final _byTypeOid = Map<int, Type>.unmodifiable({
    for (final type in values)
      if (type.hasOid) type.oid: type,
  });

  Type resolveOid(int oid) {
    return _byTypeOid[oid] ?? UnknownType(oid);
  }

  Type? tryResolveOid(int oid) {
    return _byTypeOid[oid];
  }

  late final _bySubstitutionName = Map<String, Type>.unmodifiable({
    for (final type in values)
      // We don't index serial and bigSerial types here because they're using
      // the same names as int4 and int8, respectively.
      // However, when a user is referring to these types in a query, they
      // should always resolve to integer and bigInteger.
      if (type != Type.serial &&
          type != Type.bigSerial &&
          type.nameForSubstitution != null)
        type.nameForSubstitution: type,
  });

  Type? resolveSubstitution(String name) => _bySubstitutionName[name];
}
