import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'fcm_test_response_dto.dart';

class FcmApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<FcmTestResponseDto> sendTestPush({
    required String accessToken,
  }) async {
    final body = await _apiClient.post(
      ApiEndpoints.fcmTest,
      headers: ApiClient.bearerHeaders(accessToken),
    );

    return FcmTestResponseDto.fromJson(body);
  }
}
