import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'recent_view_dto.dart';

class RecentViewApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<List<RecentViewDto>> fetchRecentViews({
    required String accessToken,
  }) async {
    final body = await _apiClient.get(
      ApiEndpoints.recentViews,
      headers: ApiClient.bearerHeaders(accessToken),
    );

    if (body['success'] != true) {
      throw Exception('최근 본 병원 목록 조회 실패');
    }

    final data = body['data'] as List<dynamic>;
    return data
        .map(
          (recentView) =>
              RecentViewDto.fromJson(recentView as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<void> createRecentView({
    required String accessToken,
    required int hospitalId,
  }) async {
    final body = await _apiClient.post(
      ApiEndpoints.recentView(hospitalId),
      headers: ApiClient.bearerHeaders(accessToken),
    );

    if (body['success'] != true) {
      throw Exception('최근 본 병원 등록 실패');
    }
  }
}
