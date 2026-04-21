import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'schedule_create_request_dto.dart';
import 'schedule_create_response_dto.dart';
import 'schedule_alarm_request_dto.dart';
import 'schedule_detail_dto.dart';
import 'schedule_summary_dto.dart';
import 'schedule_update_request_dto.dart';

class ScheduleApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<ScheduleCreateResponseDto> createSchedule({
    required String accessToken,
    required ScheduleCreateRequestDto request,
  }) async {
    final body = await _apiClient.post(
      ApiEndpoints.scheduleCreate,
      body: request.toJson(),
      headers: ApiClient.bearerHeaders(accessToken),
    );

    return ScheduleCreateResponseDto.fromJson(_dataMap(body, '일정 생성 실패'));
  }

  static Future<ScheduleDetailDto> updateSchedule({
    required String accessToken,
    required String scheduleId,
    required ScheduleUpdateRequestDto request,
  }) async {
    final body = await _apiClient.patch(
      ApiEndpoints.scheduleDetail(scheduleId),
      body: request.toJson(),
      headers: ApiClient.bearerHeaders(accessToken),
    );

    return ScheduleDetailDto.fromJson(_dataMap(body, '일정 수정 실패'));
  }

  static Future<ScheduleDetailDto> fetchScheduleDetail({
    required String accessToken,
    required String scheduleId,
  }) async {
    final body = await _apiClient.get(
      ApiEndpoints.scheduleDetail(scheduleId),
      headers: ApiClient.bearerHeaders(accessToken),
    );

    return ScheduleDetailDto.fromJson(_dataMap(body, '일정 상세 조회 실패'));
  }

  static Future<void> deleteSchedule({
    required String accessToken,
    required String scheduleId,
  }) async {
    final body = await _apiClient.delete(
      ApiEndpoints.scheduleDetail(scheduleId),
      headers: ApiClient.bearerHeaders(accessToken),
    );

    _ensureSuccess(body, '일정 삭제 실패');
  }

  static Future<void> createScheduleAlarm({
    required String accessToken,
    required String scheduleId,
    required ScheduleAlarmRequestDto request,
  }) async {
    final body = await _apiClient.post(
      ApiEndpoints.scheduleAlarms(scheduleId),
      body: request.toJson(),
      headers: ApiClient.bearerHeaders(accessToken),
    );

    _ensureSuccess(body, '일정 알림 등록 실패');
  }

  static Future<void> deleteScheduleAlarm({
    required String accessToken,
    required String scheduleId,
    required String alarmType,
  }) async {
    final body = await _apiClient.delete(
      ApiEndpoints.scheduleAlarm(scheduleId, alarmType),
      headers: ApiClient.bearerHeaders(accessToken),
    );

    _ensureSuccess(body, '일정 알림 삭제 실패');
  }

  static Future<List<ScheduleDetailDto>> fetchUpcomingSchedules({
    required String accessToken,
    required int limit,
  }) async {
    final body = await _apiClient.get(
      ApiEndpoints.scheduleUpcoming,
      queryParameters: {'limit': limit},
      headers: ApiClient.bearerHeaders(accessToken),
    );

    return _scheduleDetailList(body, '다가오는 일정 조회 실패');
  }

  static Future<ScheduleSummaryDto> fetchScheduleSummary({
    required String accessToken,
  }) async {
    final body = await _apiClient.get(
      ApiEndpoints.scheduleSummary,
      headers: ApiClient.bearerHeaders(accessToken),
    );

    return ScheduleSummaryDto.fromJson(_dataMap(body, '일정 요약 조회 실패'));
  }

  static Future<List<ScheduleDetailDto>> fetchDailySchedules({
    required String accessToken,
    required String date,
  }) async {
    final body = await _apiClient.get(
      ApiEndpoints.scheduleDaily,
      queryParameters: {'date': date},
      headers: ApiClient.bearerHeaders(accessToken),
    );

    return _scheduleDetailList(body, '일별 일정 조회 실패');
  }

  static void _ensureSuccess(Map<String, dynamic> body, String message) {
    if (body['success'] != true) {
      throw Exception(message);
    }
  }

  static Map<String, dynamic> _dataMap(
    Map<String, dynamic> body,
    String failureMessage,
  ) {
    _ensureSuccess(body, failureMessage);
    return body['data'] as Map<String, dynamic>;
  }

  static List<dynamic> _dataList(
    Map<String, dynamic> body,
    String failureMessage,
  ) {
    _ensureSuccess(body, failureMessage);
    return body['data'] as List<dynamic>;
  }

  static List<ScheduleDetailDto> _scheduleDetailList(
    Map<String, dynamic> body,
    String failureMessage,
  ) {
    return _dataList(body, failureMessage)
        .map(
          (schedule) =>
              ScheduleDetailDto.fromJson(schedule as Map<String, dynamic>),
        )
        .toList();
  }
}
