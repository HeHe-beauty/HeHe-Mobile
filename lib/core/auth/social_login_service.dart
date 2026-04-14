import 'dart:io';

import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';

import 'oauth_config.dart';

enum SocialLoginProvider { kakao, naver }

class SocialLoginCredential {
  final SocialLoginProvider provider;
  final String accessToken;
  final String? idToken;

  const SocialLoginCredential({
    required this.provider,
    required this.accessToken,
    this.idToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'accessToken': accessToken,
      if (idToken != null) 'idToken': idToken,
    };
  }
}

class SocialLoginException implements Exception {
  final String message;

  const SocialLoginException(this.message);

  @override
  String toString() => message;
}

class SocialLoginService {
  SocialLoginService._();

  static bool _isNaverInitialized = false;

  static Future<void> initialize() async {
    if (OAuthConfig.isKakaoConfigured) {
      await KakaoSdk.init(
        nativeAppKey: OAuthConfig.kakaoNativeAppKey,
        customScheme: OAuthConfig.resolvedKakaoCustomScheme,
      );
    }

    if (OAuthConfig.isNaverConfigured) {
      _isNaverInitialized = await NaverLoginSDK.initialize(
        urlScheme: Platform.isIOS ? OAuthConfig.naverUrlScheme : null,
        clientId: OAuthConfig.naverClientId,
        clientSecret: OAuthConfig.naverClientSecret,
        clientName: OAuthConfig.naverClientName,
      );
    }
  }

  static Future<SocialLoginCredential> loginWithKakao() async {
    if (!OAuthConfig.isKakaoConfigured) {
      throw const SocialLoginException('카카오 로그인 설정이 아직 연결되지 않았어요.');
    }

    try {
      final isTalkInstalled = await isKakaoTalkInstalled();
      final token = isTalkInstalled
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();
      return SocialLoginCredential(
        provider: SocialLoginProvider.kakao,
        accessToken: token.accessToken,
        idToken: token.idToken,
      );
    } catch (e) {
      throw SocialLoginException(_messageForKakaoError(e));
    }
  }

  static Future<SocialLoginCredential> loginWithNaver() async {
    if (!OAuthConfig.isNaverConfigured || !_isNaverInitialized) {
      throw const SocialLoginException('네이버 로그인 설정이 아직 연결되지 않았어요.');
    }

    String? failureMessage;
    final isLoggedIn = await NaverLoginSDK.login(
      callback: OAuthLoginCallback(
        onSuccess: () {},
        onFailure: (httpStatus, message) {
          failureMessage = message.isNotEmpty
              ? message
              : '네이버 로그인에 실패했어요. ($httpStatus)';
        },
        onError: (errorCode, message) {
          failureMessage = message.isNotEmpty
              ? message
              : '네이버 로그인에 실패했어요. ($errorCode)';
        },
      ),
    );

    if (!isLoggedIn) {
      throw SocialLoginException(failureMessage ?? '네이버 로그인이 취소되었어요.');
    }

    final accessToken = await NaverLoginSDK.getAccessToken();
    if (accessToken.isEmpty) {
      throw const SocialLoginException('네이버 로그인 토큰을 가져오지 못했어요.');
    }

    return SocialLoginCredential(
      provider: SocialLoginProvider.naver,
      accessToken: accessToken,
    );
  }

  static String _messageForKakaoError(Object error) {
    final message = error.toString();
    if (message.contains('CANCELED') ||
        message.contains('cancel') ||
        message.contains('Cancel')) {
      return '카카오 로그인이 취소되었어요.';
    }

    return '카카오 로그인에 실패했어요.';
  }
}
