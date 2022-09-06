const _microsecFromUnixEpochToY2K = 946684800 * 1000000;

DateTime dateTimeFromMicrosecondsSinceY2k(int microSecondsSinceY2K) {
  final microsecSinceUnixEpoch =
      _microsecFromUnixEpochToY2K + microSecondsSinceY2K;
  return DateTime.fromMicrosecondsSinceEpoch(microsecSinceUnixEpoch, isUtc: true);
}

int dateTimeToMicrosecondsSinceY2k(DateTime time) {
  final microsecSinceUnixEpoch = time.toUtc().microsecondsSinceEpoch;
  return microsecSinceUnixEpoch - _microsecFromUnixEpochToY2K;
}
