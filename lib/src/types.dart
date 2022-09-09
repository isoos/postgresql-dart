/*
  Adding a new type:

  1. add item to this enumeration
  2. update all switch statements on this type
  3. add pg type code -> enumeration item in PostgresBinaryDecoder.typeMap
     (lookup type code: https://doxygen.postgresql.org/pg__type_8h_source.html)
  4. add identifying key to PostgreSQLFormatIdentifier.typeStringToCodeMap.
  5. add identifying key to PostgreSQLFormat.dataTypeStringForDataType
 */

/// Supported data types.
enum PostgreSQLDataType {
  /// Must be a [String].
  text,

  /// Must be an [int] (4-byte integer)
  integer,

  /// Must be an [int] (2-byte integer)
  smallInteger,

  /// Must be an [int] (8-byte integer)
  bigInteger,

  /// Must be an [int] (autoincrementing 4-byte integer)
  serial,

  /// Must be an [int] (autoincrementing 8-byte integer)
  bigSerial,

  /// Must be a [double] (32-bit floating point value)
  real,

  /// Must be a [double] (64-bit floating point value)
  double,

  /// Must be a [bool]
  boolean,

  /// Must be a [DateTime] (microsecond date and time precision)
  timestampWithoutTimezone,

  /// Must be a [DateTime] (microsecond date and time precision)
  timestampWithTimezone,

  /// Must be a [Duration]
  interval,

  /// Must be a [List<int>]
  numeric,

  /// Must be a [DateTime] (contains year, month and day only)
  date,

  /// Must be encodable via [json.encode].
  ///
  /// Values will be encoded via [json.encode] before being sent to the database.
  jsonb,

  /// Must be encodable via [json.encode].
  ///
  /// Values will be encoded via [json.encode] before being sent to the database.
  json,

  /// Must be a [List] of [int].
  ///
  /// Each element of the list must fit into a byte (0-255).
  byteArray,

  /// Must be a [String]
  ///
  /// Used for internal pg structure names
  name,

  /// Must be a [String].
  ///
  /// Must contain 32 hexadecimal characters. May contain any number of '-' characters.
  /// When returned from database, format will be xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.
  uuid,

  /// Must be a [PgPoint]
  point,

  /// Must be a [List<bool>]
  booleanArray,

  /// Must be a [List<int>]
  integerArray,

  /// Must be a [List<String>]
  textArray,

  /// Must be a [List<double>]
  doubleArray,

  /// Must be a [String]
  varChar,

  /// Must be a [List<String>]
  varCharArray,

  /// Must be a [List] of encodable objects
  jsonbArray,
}

/// LSN is a PostgreSQL Log Sequence Number.
///
/// For more details, see: https://www.postgresql.org/docs/current/datatype-pg-lsn.html
class LSN {
  final int value;

  /// Construct an LSN from a 64-bit integer.
  LSN(this.value);

  /// Construct an LSN from XXX/XXX format used by PostgreSQL
  LSN.fromString(String string) : value = _parseLSNString(string);

  /// Formats the LSN value into the XXX/XXX format which is the text format
  /// used by PostgreSQL.
  @override
  String toString() {
    return '${(value >> 32).toRadixString(16).toUpperCase()}/${value.toUnsigned(32).toRadixString(16).toUpperCase()}';
  }

  static int _parseLSNString(String string) {
    final halves = string.split('/');
    if (halves.length != 2) {
      throw FormatException('Invalid LSN String was given ($string)');
    }
    final upperhalf = int.parse(halves[0], radix: 16) << 32;
    final lowerhalf = int.parse(halves[1], radix: 16);

    return (upperhalf + lowerhalf).toInt();
  }

  LSN operator +(LSN other) {
    return LSN(value + other.value);
  }

  LSN operator -(LSN other) {
    return LSN(value + other.value);
  }

  @override
  bool operator ==(covariant LSN other) {
    if (identical(this, other)) return true;

    return other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
