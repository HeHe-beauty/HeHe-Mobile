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

  static Future<List<ScheduleDetailDto>>? _upcomingSchedulesInFlight;
  static List<ScheduleDetailDto>? _upcomingSchedulesCache;
  static DateTime? _upcomingSchedulesFetchedAt;
  static String? _upcomingSchedulesCacheKey;
  static Future<ScheduleSummaryDto>? _scheduleSummaryInFlight;
  static ScheduleSummaryDto? _scheduleSummaryCache;
  static DateTime? _scheduleSummaryFetchedAt;
  static String? _scheduleSummaryCacheKey;
  static final Map<String, Future<List<ScheduleDetailDto>>>
  _dailySchedulesInFlight = {};
  static final Map<String, List<ScheduleDetailDto>> _dailySchedulesCache = {};
  static final Map<String, DateTime> _dailySchedulesFetchedAt = {};
  static final Map<String, Future<ScheduleDetailDto>> _scheduleDetailInFlight =
      {};
  static final Map<String, ScheduleDetailDto> _scheduleDetailCache = {};
  static final Map<String, DateTime> _scheduleDetailFetchedAt = {};

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
    final cached = _scheduleDetailCache[cacheKey];
    final fetchedAt = _scheduleDetailFetchedAt[cacheKey];

    if (!forceRefresh &&
        cached != null &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _readCacheTtl) {
      return cached;
    }

    final inFlight = _scheduleDetailInFlight[cacheKey];
    if (inFlight != null) {
      return inFlight;
    }

    final request =
        ScheduleApi.fetchScheduleDetail(
              accessToken: accessToken,
              scheduleId: scheduleId,
            )
            .then((detail) {
              _scheduleDetailCache[cacheKey] = detail;
              _scheduleDetailFetchedAt[cacheKey] = DateTime.now();
              return detail;
            })
            .whenComplete(() {
              _scheduleDetailInFlight.remove(cacheKey);
            });

    _scheduleDetailInFlight[cacheKey] = request;
    return request;
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
    final fetchedAt = _upcomingSchedulesFetchedAt;
    final cachedSchedules = _upcomingSchedulesCache;

    if (!forceRefresh &&
        cachedSchedules != null &&
        _upcomingSchedulesCacheKey == cacheKey &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _upcomingCacheTtl) {
      return cachedSchedules;
    }

    final inFlight = _upcomingSchedulesInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final request =
        ScheduleApi.fetchUpcomingSchedules(
              accessToken: accessToken,
              limit: limit,
            )
            .then((schedules) {
              _upcomingSchedulesCache = schedules;
              _upcomingSchedulesFetchedAt = DateTime.now();
              _upcomingSchedulesCacheKey = cacheKey;
              return schedules;
            })
            .catchError((Object _) {
              final emptySchedules = <ScheduleDetailDto>[];
              _upcomingSchedulesCache = emptySchedules;
              _upcomingSchedulesFetchedAt = DateTime.now();
              _upcomingSchedulesCacheKey = cacheKey;
              return emptySchedules;
            })
            .whenComplete(() {
              _upcomingSchedulesInFlight = null;
            });

    _upcomingSchedulesInFlight = request;
    return request;
  }

  static void invalidateReadCaches() {
    _upcomingSchedulesCache = null;
    _upcomingSchedulesFetchedAt = null;
    _upcomingSchedulesCacheKey = null;
    _upcomingSchedulesInFlight = null;
    _scheduleSummaryCache = null;
    _scheduleSummaryFetchedAt = null;
    _scheduleSummaryCacheKey = null;
    _scheduleSummaryInFlight = null;
    _dailySchedulesInFlight.clear();
    _dailySchedulesCache.clear();
    _dailySchedulesFetchedAt.clear();
    _scheduleDetailInFlight.clear();
    _scheduleDetailCache.clear();
    _scheduleDetailFetchedAt.clear();
  }

  static void invalidateUpcomingSchedulesCache() {
    invalidateReadCaches();
  }

  static Future<ScheduleSummaryDto> getScheduleSummary({
    required String accessToken,
    bool forceRefresh = false,
  }) async {
    final cacheKey = accessToken;
    final fetchedAt = _scheduleSummaryFetchedAt;
    final cached = _scheduleSummaryCache;

    if (!forceRefresh &&
        cached != null &&
        _scheduleSummaryCacheKey == cacheKey &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _readCacheTtl) {
      return cached;
    }

    final inFlight = _scheduleSummaryInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final request = ScheduleApi.fetchScheduleSummary(accessToken: accessToken)
        .then((summary) {
          _scheduleSummaryCache = summary;
          _scheduleSummaryFetchedAt = DateTime.now();
          _scheduleSummaryCacheKey = cacheKey;
          return summary;
        })
        .whenComplete(() {
          _scheduleSummaryInFlight = null;
        });

    _scheduleSummaryInFlight = request;
    return request;
  }

  static Future<List<ScheduleDetailDto>> getDailySchedules({
    required String accessToken,
    required String date,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$accessToken:$date';
    final cached = _dailySchedulesCache[cacheKey];
    final fetchedAt = _dailySchedulesFetchedAt[cacheKey];

    if (!forceRefresh &&
        cached != null &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _readCacheTtl) {
      return cached;
    }

    final inFlight = _dailySchedulesInFlight[cacheKey];
    if (inFlight != null) {
      return inFlight;
    }

    final request =
        ScheduleApi.fetchDailySchedules(accessToken: accessToken, date: date)
            .then((schedules) {
              _dailySchedulesCache[cacheKey] = schedules;
              _dailySchedulesFetchedAt[cacheKey] = DateTime.now();
              return schedules;
            })
            .whenComplete(() {
              _dailySchedulesInFlight.remove(cacheKey);
            });

    _dailySchedulesInFlight[cacheKey] = request;
    return request;
  }
}
