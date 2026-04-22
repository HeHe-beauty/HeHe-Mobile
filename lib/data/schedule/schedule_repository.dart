import '../../core/cache/timed_memory_cache.dart';
import '../../dtos/common/schedule/schedule_api.dart';
import '../../dtos/common/schedule/schedule_alarm_request_dto.dart';
import '../../dtos/common/schedule/schedule_create_request_dto.dart';
import '../../dtos/common/schedule/schedule_create_response_dto.dart';
import '../../dtos/common/schedule/schedule_detail_dto.dart';
import '../../dtos/common/schedule/schedule_summary_dto.dart';
import '../../dtos/common/schedule/schedule_update_request_dto.dart';
import '../../utils/visit_time_utils.dart';

class ScheduleRepository {
  static const String defaultProcedureName = '';
  static const Duration _upcomingCacheTtl = Duration(seconds: 60);
  static const Duration _readCacheTtl = Duration(seconds: 30);

  static final TimedMemoryCache<String, List<ScheduleDetailDto>>
  _upcomingSchedulesCache = TimedMemoryCache(ttl: _upcomingCacheTtl);
  static final TimedMemoryCache<String, ScheduleSummaryDto>
  _scheduleSummaryCache = TimedMemoryCache(ttl: _readCacheTtl);
  static final TimedMemoryCache<String, List<ScheduleDetailDto>>
  _dailySchedulesCache = TimedMemoryCache(ttl: _readCacheTtl);
  static final TimedMemoryCache<String, ScheduleDetailDto>
  _scheduleDetailCache = TimedMemoryCache(ttl: _readCacheTtl);

  static Future<ScheduleCreateResponseDto> createSchedule({
    required String accessToken,
    required String hospitalName,
    required DateTime visitDateTime,
    String procedureName = defaultProcedureName,
  }) async {
    final response = await ScheduleApi.createSchedule(
      accessToken: accessToken,
      request: ScheduleCreateRequestDto(
        hospitalName: hospitalName,
        procedureName: procedureName,
        visitTime: toUnixVisitTimeSeconds(visitDateTime),
      ),
    );
    invalidateReadCaches();
    return response;
  }

  static Future<ScheduleDetailDto> updateSchedule({
    required String accessToken,
    required String scheduleId,
    String? hospitalName,
    String? procedureName = defaultProcedureName,
    DateTime? visitDateTime,
  }) async {
    final request = ScheduleUpdateRequestDto(
      hospitalName: hospitalName,
      procedureName: procedureName,
      visitTime: visitDateTime == null
          ? null
          : toUnixVisitTimeSeconds(visitDateTime),
    );

    if (request.toJson().isEmpty) {
      throw ArgumentError('수정할 일정 정보가 필요합니다.');
    }

    final response = await ScheduleApi.updateSchedule(
      accessToken: accessToken,
      scheduleId: scheduleId,
      request: request,
    );
    invalidateReadCaches();
    return response;
  }

  static Future<ScheduleDetailDto> getScheduleDetail({
    required String accessToken,
    required String scheduleId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$accessToken:$scheduleId';
    return _scheduleDetailCache.get(
      cacheKey,
      forceRefresh: forceRefresh,
      fetch: () => ScheduleApi.fetchScheduleDetail(
        accessToken: accessToken,
        scheduleId: scheduleId,
      ),
    );
  }

  static Future<void> deleteSchedule({
    required String accessToken,
    required String scheduleId,
  }) async {
    await ScheduleApi.deleteSchedule(
      accessToken: accessToken,
      scheduleId: scheduleId,
    );
    invalidateReadCaches();
  }

  static Future<void> createScheduleAlarm({
    required String accessToken,
    required String scheduleId,
    required String alarmType,
  }) async {
    await ScheduleApi.createScheduleAlarm(
      accessToken: accessToken,
      scheduleId: scheduleId,
      request: ScheduleAlarmRequestDto(alarmType: alarmType),
    );
    invalidateReadCaches();
  }

  static Future<void> setScheduleReminder({
    required String accessToken,
    required String scheduleId,
    required String alarmType,
    required bool enabled,
  }) async {
    if (enabled) {
      await createScheduleAlarm(
        accessToken: accessToken,
        scheduleId: scheduleId,
        alarmType: alarmType,
      );
      return;
    }

    await deleteScheduleAlarm(
      accessToken: accessToken,
      scheduleId: scheduleId,
      alarmType: alarmType,
    );
  }

  static Future<void> deleteScheduleAlarm({
    required String accessToken,
    required String scheduleId,
    required String alarmType,
  }) async {
    await ScheduleApi.deleteScheduleAlarm(
      accessToken: accessToken,
      scheduleId: scheduleId,
      alarmType: alarmType,
    );
    invalidateReadCaches();
  }

  static Future<List<ScheduleDetailDto>> getUpcomingSchedules({
    required String accessToken,
    required int limit,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$accessToken:$limit';
    return _upcomingSchedulesCache.get(
      cacheKey,
      forceRefresh: forceRefresh,
      fetch: () => ScheduleApi.fetchUpcomingSchedules(
        accessToken: accessToken,
        limit: limit,
      ).catchError((Object _) => <ScheduleDetailDto>[]),
    );
  }

  static void invalidateReadCaches() {
    _dailySchedulesCache.clear();
    _scheduleDetailCache.clear();
    _scheduleSummaryCache.clear();
    _upcomingSchedulesCache.clear();
  }

  static void invalidateUpcomingSchedulesCache() {
    invalidateReadCaches();
  }

  static Future<ScheduleSummaryDto> getScheduleSummary({
    required String accessToken,
    bool forceRefresh = false,
  }) async {
    final cacheKey = accessToken;
    return _scheduleSummaryCache.get(
      cacheKey,
      forceRefresh: forceRefresh,
      fetch: () => ScheduleApi.fetchScheduleSummary(accessToken: accessToken),
    );
  }

  static Future<List<ScheduleDetailDto>> getDailySchedules({
    required String accessToken,
    required String date,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$accessToken:$date';
    return _dailySchedulesCache.get(
      cacheKey,
      forceRefresh: forceRefresh,
      fetch: () =>
          ScheduleApi.fetchDailySchedules(accessToken: accessToken, date: date),
    );
  }
}
