import '../../dtos/common/user/user_api.dart';
import '../../dtos/common/user/user_summary_dto.dart';

class UserRepository {
  static Future<UserSummaryDto> getUserSummary({required String accessToken}) {
    return UserApi.fetchUserSummary(accessToken: accessToken);
  }
}
