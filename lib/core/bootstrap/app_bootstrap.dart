import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../common/utils/app_time.dart';
import '../../data/auth/auth_repository.dart';
import '../../firebase_options.dart';
import '../auth/auth_session_store.dart';
import '../auth/auth_state.dart';
import '../auth/social_login_service.dart';
import '../common/app_settings_state.dart';
import '../config/app_config.dart';
import '../logging/app_log.dart';
import '../network/api_client.dart';
import '../notification/notification_permission_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationPermissionService.showLocalNotificationForMessage(
    message,
    onlyWhenDataOnly: true,
  );
}

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    await _bestEffort('FCM 초기화', _initializeFirebaseMessaging);
    await _bestEffort('앱 설정 복원', AppSettingsState.restore);
    await _bestEffort('네이버 지도 초기화', _initializeNaverMap);
    await _bestEffort('소셜 로그인 초기화', SocialLoginService.initialize);
    await _bestEffort('인증 세션 복원', _restoreAuthSession);
    await _bestEffort('서버 시간 초기화', AppTime.initialize);
  }

  static Future<void> _initializeFirebaseMessaging() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationPermissionService.initializeForAppStart();
    NotificationPermissionService.listenTokenRefreshForSession();
  }

  static Future<void> _initializeNaverMap() async {
    if (!AppConfig.isNaverMapConfigured) {
      throw StateError('NAVER_MAP_CLIENT_ID가 설정되지 않았습니다.');
    }
    await FlutterNaverMap().init(clientId: AppConfig.naverMapClientId);
  }

  static Future<void> _restoreAuthSession() async {
    final savedSession = await AuthSessionStore.read();
    if (savedSession == null) {
      _clearLocalSession();
      return;
    }

    try {
      final refreshedToken = await AuthRepository.refreshToken(
        savedSession.refreshToken,
      );
      final refreshedSession = savedSession.copyWith(
        accessToken: refreshedToken.accessToken,
        refreshToken: refreshedToken.refreshToken ?? savedSession.refreshToken,
      );

      await AuthSessionStore.write(refreshedSession);
      AuthState.restore(refreshedSession);
      await NotificationPermissionService.syncCurrentDeviceTokenPreference();
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await AuthSessionStore.clear();
        _clearLocalSession();
        return;
      }
      _restoreCachedSessionAfterTransientFailure(savedSession, error);
    } catch (error) {
      _restoreCachedSessionAfterTransientFailure(savedSession, error);
    }
  }

  static void _restoreCachedSessionAfterTransientFailure(
    AuthSession savedSession,
    Object error,
  ) {
    AuthState.restore(savedSession);
    AppLog.debug(
      '[Bootstrap] token refresh failed; cached session retained',
      error: error,
    );
  }

  static void _clearLocalSession() {
    AuthState.logOut();
    AppSettingsState.setPushEnabled(false);
  }

  static Future<void> _bestEffort(
    String taskName,
    Future<void> Function() task,
  ) async {
    try {
      await task();
      AppLog.debug('[Bootstrap] $taskName 완료');
    } catch (error, stackTrace) {
      AppLog.debug(
        '[Bootstrap] $taskName 실패',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
