import 'dart:io';

import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';

import '../config/app_config.dart';
import '../logging/app_log.dart';

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
}

class SocialLoginException implements Exception {
  final String message;
  final String? diagnosticCode;

  const SocialLoginException(this.message, {this.diagnosticCode});

  String get displayMessage {
    if (!AppConfig.authDiagnostics || diagnosticCode == null) return message;
    return '$message [$diagnosticCode]';
  }

  @override
  String toString() => message;
}

class SocialLoginService {
  SocialLoginService._();

  static bool _isNaverInitialized = false;

  static Future<void> initialize() async {
    AppLog.debug(
      '[Auth][Social] initialize start '
      'kakaoConfigured=${AppConfig.isKakaoConfigured} '
      'naverConfigured=${AppConfig.isNaverConfigured}',
    );

    if (AppConfig.isKakaoConfigured) {
      await KakaoSdk.init(
        nativeAppKey: AppConfig.kakaoNativeAppKey,
        customScheme: AppConfig.resolvedKakaoCustomScheme,
      );
      AppLog.debug('[Auth][Kakao] SDK initialized');
    }

    if (AppConfig.isNaverConfigured) {
      try {
        _isNaverInitialized = await NaverLoginSDK.initialize(
          urlScheme: Platform.isIOS ? AppConfig.naverUrlScheme : null,
          clientId: AppConfig.naverClientId,
          clientSecret: AppConfig.naverClientSecret,
          clientName: AppConfig.naverClientName,
        );
        AppLog.debug('[Auth][Naver] SDK initialized=$_isNaverInitialized');
      } catch (error, stackTrace) {
        _isNaverInitialized = false;
        AppLog.debug(
          '[Auth][Naver] SDK initialization failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  static Future<SocialLoginCredential> loginWithKakao() async {
    if (!AppConfig.isKakaoConfigured) {
      throw const SocialLoginException('카카오 로그인 설정이 아직 연결되지 않았어요.');
    }

    try {
      AppLog.debug('[Auth][Kakao] login start');
      final isTalkInstalled = await isKakaoTalkInstalled();
      AppLog.debug('[Auth][Kakao] kakaoTalkInstalled=$isTalkInstalled');

      OAuthToken token;
      if (isTalkInstalled) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (error, stackTrace) {
          if (_isKakaoCancellation(error)) rethrow;
          AppLog.debug(
            '[Auth][Kakao] KakaoTalk login failed; trying account login',
            error: error,
            stackTrace: stackTrace,
          );
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      AppLog.debug(
        '[Auth][Kakao] token received '
        'idTokenPresent=${token.idToken != null}',
      );
      return SocialLoginCredential(
        provider: SocialLoginProvider.kakao,
        accessToken: token.accessToken,
        idToken: token.idToken,
      );
    } catch (e, stackTrace) {
      AppLog.debug(
        '[Auth][Kakao] login failed (${e.runtimeType})',
        error: e,
        stackTrace: stackTrace,
      );
      throw _exceptionForKakaoError(e);
    }
  }

  static Future<SocialLoginCredential> loginWithNaver() async {
    if (!AppConfig.isNaverConfigured || !_isNaverInitialized) {
      throw const SocialLoginException('네이버 로그인 설정이 아직 연결되지 않았어요.');
    }

    AppLog.debug('[Auth][Naver] login start');
    try {
      final signedIn = await NaverLoginSDK.login();
      if (!signedIn) {
        throw const SocialLoginException('네이버 로그인이 취소되었어요.');
      }
      final accessToken = await NaverLoginSDK.getAccessToken();
      if (accessToken.isEmpty) {
        throw const SocialLoginException('네이버 로그인 토큰을 받지 못했어요.');
      }
      AppLog.debug('[Auth][Naver] token received');
      return SocialLoginCredential(
        provider: SocialLoginProvider.naver,
        accessToken: accessToken,
      );
    } on SocialLoginException {
      rethrow;
    } catch (error, stackTrace) {
      AppLog.debug(
        '[Auth][Naver] login failed (${error.runtimeType})',
        error: error,
        stackTrace: stackTrace,
      );
      throw const SocialLoginException('네이버 로그인 중 문제가 발생했어요.');
    }
  }

  static bool _isKakaoCancellation(Object error) {
    return error is KakaoClientException &&
            error.reason == ClientErrorCause.cancelled ||
        error is KakaoAuthException &&
            error.error == AuthErrorCause.accessDenied;
  }

  static SocialLoginException _exceptionForKakaoError(Object error) {
    if (_isKakaoCancellation(error)) {
      return const SocialLoginException('카카오 로그인이 취소되었어요.');
    }

    if (error is KakaoAuthException) {
      final isConfigurationError =
          error.error == AuthErrorCause.invalidClient ||
          error.error == AuthErrorCause.misconfigured ||
          error.error == AuthErrorCause.unauthorized;
      return SocialLoginException(
        isConfigurationError ? '카카오 로그인 설정을 확인해주세요.' : '카카오 로그인에 실패했어요.',
        diagnosticCode: 'KAKAO/${error.error.name}',
      );
    }

    final code = error is KakaoClientException ? error.reason.name : null;
    return SocialLoginException(
      '카카오 로그인에 실패했어요.',
      diagnosticCode: _diagnosticCode('KAKAO', code),
    );
  }

  static String? _diagnosticCode(String provider, String? code) {
    if (code == null || code.trim().isEmpty) return null;
    return '$provider/${code.trim()}';
  }
}
