class TimeZoneSettings {
  String value = 'UTC';

  /// [value] location name
  TimeZoneSettings(
    this.value, {
    this.forceDecodeTimestamptzAsUTC = true,
    this.forceDecodeTimestampAsUTC = true,
    this.forceDecodeDateAsUTC = true,
  });

  /// if true decodes the timestamp with timezone as UTC if false decodes the timestamp with timezone as the timezone defined in the connection
  bool forceDecodeTimestamptzAsUTC = true;

  /// if true decodes timestamp without timezone as UTC if false decodes timestamp without timezone as local datetime
  bool forceDecodeTimestampAsUTC = true;

  /// if true decodes date as UTC if false decodes date as local datetime
  bool forceDecodeDateAsUTC = true;
}
