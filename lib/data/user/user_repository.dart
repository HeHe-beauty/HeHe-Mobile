import '../../dtos/common/user/user_api.dart';
import '../../dtos/common/user/user_agreements_update_request_dto.dart';
import '../../dtos/common/user/user_summary_dto.dart';

class UserRepository {
  static Future<UserSummaryDto> getUserSummary({required String accessToken}) {
    return UserApi.fetchUserSummary(accessToken: accessToken);
  }

  static Future<void> deleteUser({
    required String accessToken,
    required String provider,
    required String providerAccessToken,
  }) {
    return UserApi.deleteUser(
      accessToken: accessToken,
      provider: provider,
      providerAccessToken: providerAccessToken,
    );
  }

  static Future<void> updateAgreements({
    required String accessToken,
    bool? pushAgreed,
    bool? nightAgreed,
    bool? mktAgreed,
  }) {
    return UserApi.updateAgreements(
      accessToken: accessToken,
      request: UserAgreementsUpdateRequestDto(
        pushAgreed: pushAgreed,
        nightAgreed: nightAgreed,
        mktAgreed: mktAgreed,
      ),
    );
  }
}
