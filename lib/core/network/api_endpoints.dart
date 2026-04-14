class ApiEndpoints {
  /// Time과 관련된 api 목록
  // 현재 시간 불러오기
  static const String serverTime = '/api/v1/common/time';

  /// 장비와 관련된 api 목록
  static const String equipList = '/api/v1/equipments/main';

  /// 추천 콘텐츠와 관련된 api 목록
  static const String articleList = '/api/v1/articles';

  static String articleDetail(int articleId) => '/api/v1/articles/$articleId';
}
