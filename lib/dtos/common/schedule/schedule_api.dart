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
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (body['success'] != true) {
      throw Exception('일정 생성 실패');
    }

    final data = body['data'] as Map<String, dynamic>;

    return ScheduleCreateResponseDto.fromJson(data);
  }

  static Future<ScheduleDetailDto> updateSchedule({
    required String accessToken,
    required String scheduleId,
    required ScheduleUpdateRequestDto request,
  }) async {
    final body = await _apiClient.patch(
      ApiEndpoints.scheduleDetail(scheduleId),
      body: request.toJson(),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (body['success'] != true) {
      throw Exception('일정 수정 실패');
    }

    final data = body['data'] as Map<String, dynamic>;

    return ScheduleDetailDto.fromJson(data);
  }

  static Future<ScheduleDetailDto> fetchScheduleDetail({
    required String accessToken,
    required String scheduleId,
  }) async {
    final body = await _apiClient.get(
      ApiEndpoints.scheduleDetail(scheduleId),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (body['success'] != true) {
      throw Exception('일정 상세 조회 실패');
    }

    final data = body['data'] as Map<String, dynamic>;

    return ScheduleDetailDto.fromJson(data);
  }

  static Future<void> deleteSchedule({
    required String accessToken,
    required String scheduleId,
  }) async {
    final body = await _apiClient.delete(
      ApiEndpoints.scheduleDetail(scheduleId),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (body['success'] != true) {
      throw Exception('일정 삭제 실패');
    }
  }

  static Future<void> createScheduleAlarm({
    required String accessToken,
    required String scheduleId,
    required ScheduleAlarmRequestDto request,
  }) async {
    final body = await _apiClient.post(
      ApiEndpoints.scheduleAlarms(scheduleId),
      body: request.toJson(),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (body['success'] != true) {
      throw Exception('일정 알림 등록 실패');
    }
  }

  static Future<void> deleteScheduleAlarm({
    required String accessToken,
    required String scheduleId,
    required String alarmType,
  }) async {
    final body = await _apiClient.delete(
      ApiEndpoints.scheduleAlarm(scheduleId, alarmType),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (body['success'] != true) {
      throw Exception('일정 알림 삭제 실패');
    }
  }

  static Future<List<ScheduleDetailDto>> fetchUpcomingSchedules({
    required String accessToken,
    required int limit,
  }) async {
    final body = await _apiClient.get(
      ApiEndpoints.scheduleUpcoming,
      queryParameters: {'limit': limit},
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (body['success'] != true) {
      throw Exception('다가오는 일정 조회 실패');
    }

    final data = body['data'] as List<dynamic>;

    return data
        .map(
          (schedule) =>
              ScheduleDetailDto.fromJson(schedule as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<ScheduleSummaryDto> fetchScheduleSummary({
    required String accessToken,
  }) async {
    final body = await _apiClient.get(
      ApiEndpoints.scheduleSummary,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (body['success'] != true) {
      throw Exception('일정 요약 조회 실패');
    }

    final data = body['data'] as Map<String, dynamic>;

    return ScheduleSummaryDto.fromJson(data);
  }

  static Future<List<ScheduleDetailDto>> fetchDailySchedules({
    required String accessToken,
    required String date,
  }) async {
    final body = await _apiClient.get(
      ApiEndpoints.scheduleDaily,
      queryParameters: {'date': date},
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (body['success'] != true) {
      throw Exception('일별 일정 조회 실패');
    }

    final data = body['data'] as List<dynamic>;

    return data
        .map(
          (schedule) =>
              ScheduleDetailDto.fromJson(schedule as Map<String, dynamic>),
        )
        .toList();
  }
}
