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
const timestampPosInfinityMicros = 9223372036854775807;
const timestampNegInfinityMicros = -9223372036854775807 - 1;
const datePosInfinityDays = 2147483647;
const dateNegInfinityDays = -2147483648;
