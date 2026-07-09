import '../../dtos/common/auth/auth_api.dart';
import '../../dtos/common/auth/auth_login_request_dto.dart';
import '../../dtos/common/auth/auth_login_response_dto.dart';
import '../../dtos/common/auth/auth_signup_request_dto.dart';
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

  static Future<AuthLoginResponseDto> signup({
    required String provider,
    required String accessToken,
    required bool pushAgreed,
    required bool nightAgreed,
    required bool mktAgreed,
    required bool isOverAge,
    required String termsVersion,
  }) {
    return AuthApi.signup(
      AuthSignupRequestDto(
        provider: provider,
        accessToken: accessToken,
        pushAgreed: pushAgreed,
        nightAgreed: nightAgreed,
        mktAgreed: mktAgreed,
        isOverAge: isOverAge,
        termsVersion: termsVersion,
      ),
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
