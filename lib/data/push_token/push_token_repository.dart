import '../../dtos/common/push_token/push_token_api.dart';
import '../../dtos/common/push_token/push_token_delete_request_dto.dart';
import '../../dtos/common/push_token/push_token_register_request_dto.dart';
import '../../dtos/common/push_token/push_token_response_dto.dart';

class PushTokenRepository {
  static Future<PushTokenResponseDto> register({
    required String accessToken,
    required String token,
    required String platform,
    required bool notificationPermissionGranted,
  }) {
    return PushTokenApi.register(
      accessToken,
      PushTokenRegisterRequestDto(
        token: token,
        platform: platform,
        notificationPermissionGranted: notificationPermissionGranted,
      ),
    );
  }

  static Future<PushTokenResponseDto> delete({
    required String accessToken,
    required String token,
  }) {
    return PushTokenApi.delete(
      accessToken,
      PushTokenDeleteRequestDto(token: token),
    );
  }
}
