class AppConfig {
  const AppConfig._();

  static const String apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'api.hehehe.kr',
  );

  static const String naverMapClientId = String.fromEnvironment(
    'NAVER_MAP_CLIENT_ID',
  );
  static const String kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
  );
  static const String kakaoCustomScheme = String.fromEnvironment(
    'KAKAO_CUSTOM_SCHEME',
  );
  static const String naverClientId = String.fromEnvironment('NAVER_CLIENT_ID');
  static const String naverClientSecret = String.fromEnvironment(
    'NAVER_CLIENT_SECRET',
  );
  static const String naverClientName = String.fromEnvironment(
    'NAVER_CLIENT_NAME',
    defaultValue: 'HeHe',
  );

  /// 내부 테스트에서만 소셜 SDK의 안전한 오류 코드까지 화면에 표시한다.
  static const bool authDiagnostics = bool.fromEnvironment('AUTH_DIAGNOSTICS');

  static bool get isNaverMapConfigured => naverMapClientId.isNotEmpty;
  static bool get isKakaoConfigured => kakaoNativeAppKey.isNotEmpty;
  static bool get isNaverConfigured {
    return naverClientId.isNotEmpty && naverClientSecret.isNotEmpty;
  }

  static String get resolvedKakaoCustomScheme {
    if (kakaoCustomScheme.isNotEmpty) return kakaoCustomScheme;
    if (kakaoNativeAppKey.isEmpty) return '';
    return 'kakao$kakaoNativeAppKey';
  }
}
