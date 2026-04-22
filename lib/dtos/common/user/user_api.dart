import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'user_summary_dto.dart';

class UserApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<UserSummaryDto> fetchUserSummary({
    required String accessToken,
  }) async {
    final body = await _apiClient.get(
      ApiEndpoints.userSummary,
      headers: ApiClient.bearerHeaders(accessToken),
    );

    if (body['success'] != true) {
      throw Exception('유저 요약 조회 실패');
    }

    final data = body['data'] as Map<String, dynamic>;
    return UserSummaryDto.fromJson(data);
  }
}
