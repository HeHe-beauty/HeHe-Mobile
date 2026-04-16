import '../../dtos/common/auth/auth_api.dart';
import '../../dtos/common/auth/auth_login_request_dto.dart';
import '../../dtos/common/auth/auth_login_response_dto.dart';
import '../../dtos/common/auth/auth_token_refresh_request_dto.dart';
import '../../dtos/common/auth/auth_token_refresh_response_dto.dart';

class AuthRepository {
  static Future<AuthLoginResponseDto> login({
    required String provider,
    required String accessToken,
  }) {
    return AuthApi.login(
      AuthLoginRequestDto(provider: provider, accessToken: accessToken),
    );
  }

  static Future<void> logout(String accessToken) {
    return AuthApi.logout(accessToken);
  }

  static Future<AuthTokenRefreshResponseDto> refreshToken(String refreshToken) {
    return AuthApi.refreshToken(
      AuthTokenRefreshRequestDto(refreshToken: refreshToken),
    );
  }
}
