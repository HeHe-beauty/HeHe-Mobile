class ApiEndpoints {
  /// Time과 관련된 api 목록
  // 현재 시간 불러오기
  static const String serverTime = '/api/v1/common/time';

  /// 인증과 관련된 api 목록
  static const String authLogin = '/api/v1/auth/login';
  static const String authLogout = '/api/v1/auth/logout';
  static const String authTokenRefresh = '/api/v1/auth/token/refresh';

  /// 유저와 관련된 api 목록
  static const String userSummary = '/api/v1/users/summary';

  /// 푸시 토큰과 관련된 api 목록
  static const String pushTokens = '/api/v1/push-tokens';
  static const String fcmTest = '/api/v1/fcm/test';

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

  /// 찜하기와 관련된 api 목록
  static const String bookmarks = '/api/v1/bookmarks';
  static String bookmark(int hospitalId) => '/api/v1/bookmarks/$hospitalId';

  /// 문의 내역과 관련된 api 목록
  static const String contacts = '/api/v1/contacts';
  static String contact(int contactId) => '/api/v1/contacts/$contactId';

  /// 최근 본 병원과 관련된 api 목록
  static const String recentViews = '/api/v1/recent-views';
  static String recentView(int hospitalId) =>
      '/api/v1/recent-views/$hospitalId';

  /// 일정과 관련된 api 목록
  static const String scheduleCreate = '/api/v1/schedules';
  static const String scheduleUpcoming = '/api/v1/schedules/upcoming';
  static const String scheduleSummary = '/api/v1/schedules/summary';
  static const String scheduleDaily = '/api/v1/schedules/daily';
  static String scheduleDetail(String scheduleId) =>
      '/api/v1/schedules/$scheduleId';
  static String scheduleAlarms(String scheduleId) =>
      '/api/v1/schedules/$scheduleId/alarms';
  static String scheduleAlarm(String scheduleId, String alarmType) =>
      '/api/v1/schedules/$scheduleId/alarms/$alarmType';
}
