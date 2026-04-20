import 'package:hehe/common/utils/app_time.dart';

import '../models/calendar_schedule.dart';
import '../utils/calendar_schedule_utils.dart';
import '../widgets/visit_schedule_bottom_sheet.dart';

class CalendarScheduleStore {
  static int _idSeed = 0;

  static final Map<DateTime, List<CalendarSchedule>> _scheduleMap = {};

  static String createId() {
    _idSeed += 1;
    return 'schedule_${AppTime.now().microsecondsSinceEpoch}_$_idSeed';
  }

  static Map<DateTime, List<CalendarSchedule>> snapshot() {
    return {
      for (final entry in _scheduleMap.entries)
        entry.key: entry.value.map((schedule) => schedule.copyWith()).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime)),
    };
  }

  static DateTime upsertFromResult(
    VisitScheduleResult result, {
    String? scheduleId,
  }) {
    final schedule = createScheduleFromResult(result, scheduleId: scheduleId);
    upsert(schedule);
    return calendarDateOnly(result.dateTime);
  }

  static CalendarSchedule createScheduleFromResult(
    VisitScheduleResult result, {
    String? scheduleId,
    CalendarSchedule? seedSchedule,
  }) {
    return CalendarSchedule(
      id: scheduleId ?? seedSchedule?.id ?? createId(),
      hospitalName: _normalizeHospitalName(result.hospitalName),
      dateTime: result.dateTime,
      isThreeDaysBefore: seedSchedule?.isThreeDaysBefore ?? false,
      isOneDayBefore: seedSchedule?.isOneDayBefore ?? false,
      isOneHourBefore: seedSchedule?.isOneHourBefore ?? false,
    );
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

  static String _normalizeHospitalName(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? '병원명을 입력해주세요' : normalized;
  }
}
