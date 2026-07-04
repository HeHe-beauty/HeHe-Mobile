import 'dart:io';

import 'package:flutter/foundation.dart';
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
    debugPrint(
      '[Auth][Social] initialize start '
      'kakaoConfigured=${OAuthConfig.isKakaoConfigured} '
      'naverConfigured=${OAuthConfig.isNaverConfigured}',
    );

    if (OAuthConfig.isKakaoConfigured) {
      await KakaoSdk.init(
        nativeAppKey: OAuthConfig.kakaoNativeAppKey,
        customScheme: OAuthConfig.resolvedKakaoCustomScheme,
      );
      debugPrint('[Auth][Kakao] SDK initialized');
    }

    if (OAuthConfig.isNaverConfigured) {
      _isNaverInitialized = await NaverLoginSDK.initialize(
        urlScheme: Platform.isIOS ? OAuthConfig.naverUrlScheme : null,
        clientId: OAuthConfig.naverClientId,
        clientSecret: OAuthConfig.naverClientSecret,
        clientName: OAuthConfig.naverClientName,
      );
      debugPrint('[Auth][Naver] SDK initialized=$_isNaverInitialized');
    }
  }

  static Future<SocialLoginCredential> loginWithKakao() async {
    if (!OAuthConfig.isKakaoConfigured) {
      throw const SocialLoginException('카카오 로그인 설정이 아직 연결되지 않았어요.');
    }

    try {
      debugPrint('[Auth][Kakao] login start');
      final isTalkInstalled = await isKakaoTalkInstalled();
      debugPrint('[Auth][Kakao] kakaoTalkInstalled=$isTalkInstalled');
      final token = isTalkInstalled
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();
      debugPrint(
        '[Auth][Kakao] token received '
        'idTokenPresent=${token.idToken != null}',
      );
      return SocialLoginCredential(
        provider: SocialLoginProvider.kakao,
        accessToken: token.accessToken,
        idToken: token.idToken,
      );
    } catch (e) {
      debugPrint('[Auth][Kakao] login error: $e');
      throw SocialLoginException(_messageForKakaoError(e));
    }
  }

  static Future<SocialLoginCredential> loginWithNaver() async {
    if (!OAuthConfig.isNaverConfigured || !_isNaverInitialized) {
      throw const SocialLoginException('네이버 로그인 설정이 아직 연결되지 않았어요.');
    }

    debugPrint('[Auth][Naver] login start initialized=$_isNaverInitialized');
    String? failureMessage;
    final isLoggedIn = await NaverLoginSDK.login(
      callback: OAuthLoginCallback(
        onSuccess: () {
          debugPrint('[Auth][Naver] SDK login success callback');
        },
        onFailure: (httpStatus, message) {
          failureMessage = message.isNotEmpty
              ? message
              : '네이버 로그인에 실패했어요. ($httpStatus)';
          debugPrint(
            '[Auth][Naver] SDK login failure '
            'httpStatus=$httpStatus message=$message',
          );
        },
        onError: (errorCode, message) {
          failureMessage = message.isNotEmpty
              ? message
              : '네이버 로그인에 실패했어요. ($errorCode)';
          debugPrint(
            '[Auth][Naver] SDK login error '
            'errorCode=$errorCode message=$message',
          );
        },
      ),
    );

    if (!isLoggedIn) {
      debugPrint('[Auth][Naver] login canceled/failed: $failureMessage');
      throw SocialLoginException(failureMessage ?? '네이버 로그인이 취소되었어요.');
    }

    final accessToken = await NaverLoginSDK.getAccessToken();
    if (accessToken.isEmpty) {
      debugPrint('[Auth][Naver] access token is empty after SDK login');
      throw const SocialLoginException('네이버 로그인 토큰을 가져오지 못했어요.');
    }
    debugPrint('[Auth][Naver] token received');

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
