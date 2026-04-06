import '../models/calendar_schedule.dart';
import '../utils/calendar_schedule_utils.dart';
import '../widgets/visit_schedule_bottom_sheet.dart';

class CalendarScheduleStore {
  static int _idSeed = 0;

  static final Map<DateTime, List<CalendarSchedule>> _scheduleMap = {
    calendarDateOnly(DateTime(2026, 6, 11)): [
      CalendarSchedule(
        id: createId(),
        hospitalName: '샤프 의원',
        dateTime: DateTime(2026, 6, 11, 10, 30),
        isThreeDaysBefore: true,
      ),
      CalendarSchedule(
        id: createId(),
        hospitalName: '리프 클리닉',
        dateTime: DateTime(2026, 6, 11, 19),
        isOneDayBefore: true,
      ),
    ],
    calendarDateOnly(DateTime(2026, 6, 13)): [
      CalendarSchedule(
        id: createId(),
        hospitalName: 'YY 의원',
        dateTime: DateTime(2026, 6, 13, 14, 30),
        isThreeDaysBefore: true,
        isOneDayBefore: true,
      ),
      CalendarSchedule(
        id: createId(),
        hospitalName: '아크 피부과',
        dateTime: DateTime(2026, 6, 13, 17),
        isOneHourBefore: true,
      ),
    ],
    calendarDateOnly(DateTime(2026, 6, 28)): [
      CalendarSchedule(
        id: createId(),
        hospitalName: '범석 재호',
        dateTime: DateTime(2026, 6, 28, 9),
        isOneDayBefore: true,
        isOneHourBefore: true,
      ),
    ],
  };

  static String createId() {
    _idSeed += 1;
    return 'schedule_${DateTime.now().microsecondsSinceEpoch}_$_idSeed';
  }

  static Map<DateTime, List<CalendarSchedule>> snapshot() {
    return {
      for (final entry in _scheduleMap.entries)
        entry.key: entry.value.map((schedule) => schedule.copyWith()).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime)),
    };
  }

  static DateTime upsertFromResult(VisitScheduleResult result) {
    final schedule = CalendarSchedule(
      id: createId(),
      hospitalName: result.hospitalName.isEmpty
          ? '병원명을 입력해주세요'
          : result.hospitalName,
      dateTime: result.dateTime,
    );
    upsert(schedule);
    return calendarDateOnly(result.dateTime);
  }

  static void upsert(CalendarSchedule schedule) {
    removeById(schedule.id);

    final targetDate = calendarDateOnly(schedule.dateTime);
    final schedules = _scheduleMap.putIfAbsent(
      targetDate,
      () => <CalendarSchedule>[],
    );
    schedules.add(schedule.copyWith());
    schedules.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  static void removeById(String scheduleId) {
    final emptyDates = <DateTime>[];

    for (final entry in _scheduleMap.entries) {
      entry.value.removeWhere((schedule) => schedule.id == scheduleId);
      if (entry.value.isEmpty) {
        emptyDates.add(entry.key);
      }
    }

    for (final date in emptyDates) {
      _scheduleMap.remove(date);
    }
  }
}
