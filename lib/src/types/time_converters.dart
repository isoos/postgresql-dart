final _microsecFromUnixEpochToY2K = DateTime.utc(
  2000,
  1,
  1,
).microsecondsSinceEpoch;

DateTime dateTimeFromMicrosecondsSinceY2k(int microSecondsSinceY2K) {
  final microsecSinceUnixEpoch =
      _microsecFromUnixEpochToY2K + microSecondsSinceY2K;
  return DateTime.fromMicrosecondsSinceEpoch(
    microsecSinceUnixEpoch,
    isUtc: true,
  );
}

int dateTimeToMicrosecondsSinceY2k(DateTime time) {
  final microsecSinceUnixEpoch = time.toUtc().microsecondsSinceEpoch;
  return microsecSinceUnixEpoch - _microsecFromUnixEpochToY2K;
}

final _y2k = DateTime.utc(2000);

DateTime dateTimeFromDaysSinceY2k(int daysSinceY2K) {
  return _y2k.add(Duration(days: daysSinceY2K));
}

int dateTimeToDaysSinceY2k(DateTime time) {
  return time.toUtc().difference(_y2k).inDays;
}

/// Binary sentinels for `timestamp`/`timestamptz`/`date` `infinity` values.
///
/// The 64-bit ones are built from their 32-bit halves: JavaScript cannot
/// represent them exactly, and a literal that it cannot represent does not
/// compile there.
const timestampPosInfinityMicros = 0x7FFFFFFF * 0x100000000 + 0xFFFFFFFF;
const timestampNegInfinityMicros = -timestampPosInfinityMicros - 1;
const datePosInfinityDays = 2147483647;
const dateNegInfinityDays = -2147483648;
