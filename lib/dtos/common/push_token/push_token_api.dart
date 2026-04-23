import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'push_token_delete_request_dto.dart';
import 'push_token_register_request_dto.dart';
import 'push_token_response_dto.dart';

class PushTokenApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<PushTokenResponseDto> register(
    String accessToken,
    PushTokenRegisterRequestDto request,
  ) async {
    final body = await _apiClient.post(
      ApiEndpoints.pushTokens,
      body: request.toJson(),
      headers: ApiClient.bearerHeaders(accessToken),
    );

    return PushTokenResponseDto.fromJson(body);
  }

  static Future<PushTokenResponseDto> delete(
    String accessToken,
    PushTokenDeleteRequestDto request,
  ) async {
    final body = await _apiClient.delete(
      ApiEndpoints.pushTokens,
      body: request.toJson(),
      headers: ApiClient.bearerHeaders(accessToken),
    );

    return PushTokenResponseDto.fromJson(body);
  }
}
