import '../../dtos/common/recent_view/recent_view_api.dart';
import '../../dtos/common/recent_view/recent_view_dto.dart';

class RecentViewRepository {
  static Future<List<RecentViewDto>> getRecentViews({
    required String accessToken,
  }) {
    return RecentViewApi.fetchRecentViews(accessToken: accessToken);
  }

  static Future<void> addRecentView({
    required String accessToken,
    required int hospitalId,
  }) {
    return RecentViewApi.createRecentView(
      accessToken: accessToken,
      hospitalId: hospitalId,
    );
  }
}
