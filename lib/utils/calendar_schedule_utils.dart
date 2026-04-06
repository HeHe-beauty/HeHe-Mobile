import '../models/calendar_schedule.dart';

const List<String> calendarWeekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

DateTime calendarDateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String formatMonthDotLabel(DateTime date) => '${date.year}. ${date.month}';

String formatScheduleTime(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute;
  final period = hour < 12 ? '오전' : '오후';
  final displayHour = hour == 0
      ? 12
      : hour > 12
      ? hour - 12
      : hour;
  return '$period $displayHour:${minute.toString().padLeft(2, '0')}';
}

String formatScheduleDate(DateTime dateTime) {
  final weekdayLabel = calendarWeekdayLabels[dateTime.weekday % 7];
  return '${dateTime.month}월 ${dateTime.day}일 $weekdayLabel요일';
}

String formatReminderSummary(CalendarSchedule schedule) {
  final items = <String>[];
  if (schedule.isThreeDaysBefore) items.add('방문 3일 전에 알림');
  if (schedule.isOneDayBefore) items.add('방문 1일 전에 알림');
  if (schedule.isOneHourBefore) items.add('방문 1시간 전에 알림');

  if (items.isEmpty) {
    return '알림 없음';
  }

  return items.join(' · ');
}

String formatCompactScheduleDate(DateTime dateTime) {
  final weekdayLabel = calendarWeekdayLabels[dateTime.weekday % 7];
  return '${dateTime.month}월 ${dateTime.day}일($weekdayLabel) ${formatScheduleTime(dateTime)}';
}

String formatRelativeFromToday(DateTime dateTime, {DateTime? referenceDate}) {
  final now = referenceDate ?? DateTime.now();
  final today = calendarDateOnly(now);
  final scheduleDate = calendarDateOnly(dateTime);
  final diff = scheduleDate.difference(today).inDays;

  if (diff <= 0) {
    return '오늘';
  }

  return '$diff일 후';
}

String buildNearestReservationTitle(
  CalendarSchedule schedule, {
  DateTime? referenceDate,
}) {
  final now = referenceDate ?? DateTime.now();
  final today = calendarDateOnly(now);
  final scheduleDate = calendarDateOnly(schedule.dateTime);
  final diff = scheduleDate.difference(today).inDays;

  if (diff <= 0) {
    return '${schedule.hospitalName} 예약 당일';
  }

  return '${schedule.hospitalName} 예약 $diff일 전';
}

String formatTodayReferenceLabel({DateTime? referenceDate}) {
  final now = referenceDate ?? DateTime.now();
  final weekdayLabel = calendarWeekdayLabels[now.weekday % 7];
  return 'Today · ${now.month}월 ${now.day}일 ($weekdayLabel)';
}

List<CalendarSchedule> upcomingSchedulesFromToday(
  Iterable<CalendarSchedule> schedules, {
  DateTime? referenceDate,
}) {
  final now = referenceDate ?? DateTime.now();
  final today = calendarDateOnly(now);

  return schedules.where((schedule) {
    return !calendarDateOnly(schedule.dateTime).isBefore(today);
  }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
}
