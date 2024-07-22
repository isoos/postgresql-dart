/// A class to configure time zone settings for decoding timestamps and dates.
class TimeZoneSettings {
  /// The default time zone value.
  /// 
  /// The [value] represents the name of the time zone location. Default is 'UTC'.
  String value = 'UTC';

  /// Creates a new instance of [TimeZoneSettings].
  /// 
  /// [value] is the name of the time zone location.
  /// 
  /// The optional named parameters:
  /// - [forceDecodeTimestamptzAsUTC]: if true, decodes timestamps with timezone (timestamptz) as UTC. If false, decodes them using the timezone defined in the connection.
  /// - [forceDecodeTimestampAsUTC]: if true, decodes timestamps without timezone (timestamp) as UTC. If false, decodes them as local datetime.
  /// - [forceDecodeDateAsUTC]: if true, decodes dates as UTC. If false, decodes them as local datetime.
  TimeZoneSettings(
    this.value, {
    this.forceDecodeTimestamptzAsUTC = true,
    this.forceDecodeTimestampAsUTC = true,
    this.forceDecodeDateAsUTC = true,
  });

  /// If true, decodes the timestamp with timezone (timestamptz) as UTC.
  /// If false, decodes the timestamp with timezone using the timezone defined in the connection.
  bool forceDecodeTimestamptzAsUTC = true;

  /// If true, decodes the timestamp without timezone (timestamp) as UTC.
  /// If false, decodes the timestamp without timezone as local datetime.
  bool forceDecodeTimestampAsUTC = true;

  /// If true, decodes the date as UTC.
  /// If false, decodes the date as local datetime.
  bool forceDecodeDateAsUTC = true;
}
