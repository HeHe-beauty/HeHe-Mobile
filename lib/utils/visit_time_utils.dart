const Duration _kstOffset = Duration(hours: 9);

String toUnixVisitTime(DateTime dateTime) {
  return toUnixVisitTimeSeconds(dateTime).toString();
}

int toUnixVisitTimeSeconds(DateTime dateTime) {
  return dateTime.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
}

DateTime dateTimeFromUnixVisitTime(num visitTime) {
  return DateTime.fromMillisecondsSinceEpoch(
    visitTime.toInt() * Duration.millisecondsPerSecond,
    isUtc: true,
  ).add(_kstOffset);
}
