class OAuthConfig {
  OAuthConfig._();

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
    defaultValue: 'Hehe',
  );
  static const String naverUrlScheme = String.fromEnvironment(
    'NAVER_URL_SCHEME',
  );

  static bool get isKakaoConfigured => kakaoNativeAppKey.isNotEmpty;

  static String get resolvedKakaoCustomScheme {
    if (kakaoCustomScheme.isNotEmpty) return kakaoCustomScheme;
    if (kakaoNativeAppKey.isEmpty) return '';
    return 'kakao$kakaoNativeAppKey';
  }

  static bool get isNaverConfigured {
    return naverClientId.isNotEmpty && naverClientSecret.isNotEmpty;
  }
}
