class ApiEndpoints {
  /// Time과 관련된 api 목록
  // 현재 시간 불러오기
  static const String serverTime = '/api/v1/common/time';

  /// 인증과 관련된 api 목록
  static const String authLogin = '/api/v1/auth/login';
  static const String authLogout = '/api/v1/auth/logout';
  static const String authTokenRefresh = '/api/v1/auth/token/refresh';

  /// 장비와 관련된 api 목록
  static const String equipList = '/api/v1/equipments/main';
  static String equipDetail(int equipId) => '/api/v1/equipments/$equipId';

  /// 추천 콘텐츠와 관련된 api 목록
  static const String articleList = '/api/v1/articles';
  static String articleDetail(int articleId) => '/api/v1/articles/$articleId';

  /// 병원과 관련된 api 목록
  static const String hospitalList = '/api/v1/hospitals';
  static const String hospitalMap = '/api/v1/hospitals/map';
  static String hospitalDetail(int hospitalId) =>
      '/api/v1/hospitals/$hospitalId';
}
