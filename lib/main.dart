import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/common/app_settings_state.dart';
import 'core/auth/auth_session_store.dart';
import 'core/auth/auth_state.dart';
import 'core/network/api_client.dart';
import 'core/notification/notification_permission_service.dart';
import 'data/auth/auth_repository.dart';
import 'core/auth/social_login_service.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

import 'common/utils/app_time.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🔥 main start');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await _runStartupTask(
    successMessage: null,
    errorMessage: '🔥 fcm init error',
    task: _initializeFirebaseMessaging,
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await _runStartupTask(
    successMessage: '🔥 app settings restore done',
    errorMessage: '🔥 app settings restore error',
    task: AppSettingsState.restore,
  );

  await FlutterNaverMap().init(clientId: 'yi5mqthvb4');
  debugPrint('🔥 naver map init done');

  await _runStartupTask(
    successMessage: '🔥 social login init done',
    errorMessage: '🔥 social login init error',
    task: SocialLoginService.initialize,
  );

  await _runStartupTask(
    successMessage: '🔥 auth session restore done',
    errorMessage: '🔥 auth session restore error',
    task: _restoreAuthSession,
  );

  await _runStartupTask(
    successMessage: '🔥 app time init done',
    errorMessage: '🔥 app time init error',
    task: AppTime.initialize,
  );

  runApp(const MyApp());
}

Future<void> _initializeFirebaseMessaging() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationPermissionService.initializeForAppStart();
  NotificationPermissionService.listenTokenRefreshForSession();
}

Future<void> _restoreAuthSession() async {
  final savedSession = await AuthSessionStore.read();
  if (savedSession == null) {
    AuthState.logOut();
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
    await NotificationPermissionService.registerCurrentDeviceToken(
      accessToken: refreshedSession.accessToken,
    );
  } on ApiException catch (e) {
    debugPrint('🔥 auth token refresh error: $e');

    if (e.statusCode == 401 || e.statusCode == 403) {
      await AuthSessionStore.clear();
      AuthState.logOut();
      debugPrint('🔥 auth session cleared due to invalid refresh token');
      return;
    }

    AuthState.logOut();
    rethrow;
  } catch (e, stack) {
    AuthState.logOut();
    debugPrint('🔥 auth token refresh error: $e');
    debugPrint('$stack');
    rethrow;
  }
}

Future<void> _runStartupTask({
  required String? successMessage,
  required String errorMessage,
  required Future<void> Function() task,
}) async {
  try {
    await task();
    if (successMessage != null) {
      debugPrint(successMessage);
    }
  } catch (e, stack) {
    debugPrint('$errorMessage: $e');
    debugPrint('$stack');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    NotificationPermissionService.initializeMessageHandlers();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettingsState.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: NotificationPermissionService.navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
