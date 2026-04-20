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

  static Future<ScheduleCreateResponseDto> createSchedule({
    required String accessToken,
    required String hospitalName,
    required DateTime visitDateTime,
    String procedureName = defaultProcedureName,
  }) {
    return ScheduleApi.createSchedule(
      accessToken: accessToken,
      request: ScheduleCreateRequestDto(
        hospitalName: hospitalName,
        procedureName: procedureName,
        visitTime: toUnixVisitTime(visitDateTime),
      ),
    );
  }

  static Future<ScheduleDetailDto> updateSchedule({
    required String accessToken,
    required String scheduleId,
    String? hospitalName,
    String? procedureName = defaultProcedureName,
    DateTime? visitDateTime,
  }) {
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

    return ScheduleApi.updateSchedule(
      accessToken: accessToken,
      scheduleId: scheduleId,
      request: request,
    );
  }

  static Future<ScheduleDetailDto> getScheduleDetail({
    required String accessToken,
    required String scheduleId,
  }) {
    return ScheduleApi.fetchScheduleDetail(
      accessToken: accessToken,
      scheduleId: scheduleId,
    );
  }

  static Future<void> deleteSchedule({
    required String accessToken,
    required String scheduleId,
  }) {
    return ScheduleApi.deleteSchedule(
      accessToken: accessToken,
      scheduleId: scheduleId,
    );
  }

  static Future<void> createScheduleAlarm({
    required String accessToken,
    required String scheduleId,
    required String alarmType,
  }) {
    return ScheduleApi.createScheduleAlarm(
      accessToken: accessToken,
      scheduleId: scheduleId,
      request: ScheduleAlarmRequestDto(alarmType: alarmType),
    );
  }

  static Future<void> deleteScheduleAlarm({
    required String accessToken,
    required String scheduleId,
    required String alarmType,
  }) {
    return ScheduleApi.deleteScheduleAlarm(
      accessToken: accessToken,
      scheduleId: scheduleId,
      alarmType: alarmType,
    );
  }

  static Future<List<ScheduleDetailDto>> getUpcomingSchedules({
    required String accessToken,
    required int limit,
  }) {
    return ScheduleApi.fetchUpcomingSchedules(
      accessToken: accessToken,
      limit: limit,
    );
  }

  static Future<ScheduleSummaryDto> getScheduleSummary({
    required String accessToken,
  }) {
    return ScheduleApi.fetchScheduleSummary(accessToken: accessToken);
  }

  static Future<List<ScheduleDetailDto>> getDailySchedules({
    required String accessToken,
    required String date,
  }) {
    return ScheduleApi.fetchDailySchedules(
      accessToken: accessToken,
      date: date,
    );
  }
}
