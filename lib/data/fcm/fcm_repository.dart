import '../../dtos/common/fcm/fcm_api.dart';
import '../../dtos/common/fcm/fcm_test_response_dto.dart';

class FcmRepository {
  static Future<FcmTestResponseDto> sendTestPush({
    required String accessToken,
  }) {
    return FcmApi.sendTestPush(accessToken: accessToken);
  }
}
