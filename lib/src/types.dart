/*
  Adding a new type:

  1. add item to this enumeration
  2. update all switch statements on this type
  3. add pg type code -> enumeration item in PostgresBinaryDecoder.typeMap (lookup type code: https://doxygen.postgresql.org/include_2catalog_2pg__type_8h_source.html)
  4. add identifying key to PostgreSQLFormatIdentifier.typeStringToCodeMap.
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

  /// Must be a [DateTime] (contains year, month and day only)
  date,

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
  uuid
}