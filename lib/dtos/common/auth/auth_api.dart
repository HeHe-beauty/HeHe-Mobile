import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'auth_login_request_dto.dart';
import 'auth_login_response_dto.dart';
import 'auth_token_refresh_request_dto.dart';
import 'auth_token_refresh_response_dto.dart';

class AuthApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<AuthLoginResponseDto> login(AuthLoginRequestDto request) async {
    final requestBody = request.toJson();
    debugPrint('Auth login request body: $requestBody');

    final body = await _apiClient.post(
      ApiEndpoints.authLogin,
      body: requestBody,
    );

    final data = body['data'] as Map<String, dynamic>;

    return AuthLoginResponseDto.fromJson(data);
  }

  static Future<void> logout(String accessToken) async {
    await _apiClient.post(
      ApiEndpoints.authLogout,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }

  static Future<AuthTokenRefreshResponseDto> refreshToken(
    AuthTokenRefreshRequestDto request,
  ) async {
    final body = await _apiClient.post(
      ApiEndpoints.authTokenRefresh,
      body: request.toJson(),
    );

    final data = body['data'] as Map<String, dynamic>;

    return AuthTokenRefreshResponseDto.fromJson(data);
  }
}
