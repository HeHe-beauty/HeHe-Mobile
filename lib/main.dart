import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter/services.dart';

import 'core/common/app_settings_state.dart';
import 'core/auth/auth_session_store.dart';
import 'core/auth/auth_state.dart';
import 'data/auth/auth_repository.dart';
import 'core/auth/social_login_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

import 'common/utils/app_time.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🔥 main start');

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await FlutterNaverMap().init(clientId: 'yi5mqthvb4');
  debugPrint('🔥 naver map init done');

  try {
    await SocialLoginService.initialize();
    debugPrint('🔥 social login init done');
  } catch (e, stack) {
    debugPrint('🔥 social login init error: $e');
    debugPrint('$stack');
  }

  try {
    final savedSession = await AuthSessionStore.read();
    if (savedSession != null) {
      AuthState.restore(savedSession);

      try {
        final refreshedToken = await AuthRepository.refreshToken(
          savedSession.refreshToken,
        );
        final refreshedSession = savedSession.copyWith(
          accessToken: refreshedToken.accessToken,
        );

        await AuthSessionStore.write(refreshedSession);
        AuthState.restore(refreshedSession);
      } catch (e, stack) {
        debugPrint('🔥 auth token refresh error: $e');
        debugPrint('$stack');
      }
    }
    debugPrint('🔥 auth session restore done');
  } catch (e, stack) {
    debugPrint('🔥 auth session restore error: $e');
    debugPrint('$stack');
  }

  try {
    await AppTime.initialize();
    debugPrint('🔥 app time init done');
  } catch (e, stack) {
    debugPrint('🔥 app time init error: $e');
    debugPrint('$stack');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettingsState.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
