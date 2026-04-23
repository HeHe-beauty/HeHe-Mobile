import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../data/push_token/push_token_repository.dart';
import '../../screens/home_screen.dart';
import '../../utils/app_snackbar.dart';
import '../auth/auth_state.dart';
import '../common/app_settings_state.dart';

class NotificationPermissionService {
  const NotificationPermissionService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  static StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;

  static Future<void> initializeForAppStart() async {
    final hasRequested =
        await AppSettingsState.hasRequestedNotificationPermission();

    if (!hasRequested) {
      final settings = await _messaging.requestPermission();
      await AppSettingsState.markNotificationPermissionRequested();
      debugPrint(
        'FCM first-launch permission request result: '
        '${settings.authorizationStatus}',
      );
    } else {
      final settings = await _messaging.getNotificationSettings();
      debugPrint(
        'FCM app-start permission request skipped: '
        '${settings.authorizationStatus}',
      );
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('FCM token is null');
      return;
    }

    debugPrint('FCM token: $token');
  }

  static Future<void> initializeMessageHandlers() async {
    _foregroundMessageSubscription ??= FirebaseMessaging.onMessage.listen((
      message,
    ) {
      _handleForegroundMessage(message);
    });

    _messageOpenedAppSubscription ??= FirebaseMessaging.onMessageOpenedApp
        .listen((message) {
          _handleOpenedMessage(message);
        });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleOpenedMessage(initialMessage);
      });
    }
  }

  static void listenTokenRefreshForSession() {
    _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh
        .listen((token) async {
          final accessToken = AuthState.session?.accessToken;
          if (accessToken == null || accessToken.isEmpty) {
            debugPrint('FCM token refreshed while logged out');
            return;
          }

          await registerCurrentDeviceToken(
            accessToken: accessToken,
            tokenOverride: token,
          );
        });
  }

  static Future<void> registerCurrentDeviceToken({
    required String accessToken,
    String? tokenOverride,
  }) async {
    if (accessToken.isEmpty) return;

    try {
      final token = tokenOverride ?? await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM skipped push token register: token is null');
        return;
      }

      final settings = await _messaging.getNotificationSettings();
      final response = await PushTokenRepository.register(
        accessToken: accessToken,
        token: token,
        platform: _currentPlatform,
        notificationPermissionGranted: _isGranted(settings.authorizationStatus),
      );

      debugPrint('FCM push token register success: ${response.success}');
    } catch (e, stack) {
      debugPrint('FCM push token register failed: $e');
      debugPrint('$stack');
    }
  }

  static Future<void> unregisterCurrentDeviceToken({
    required String accessToken,
  }) async {
    if (accessToken.isEmpty) return;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM skipped push token delete: token is null');
        return;
      }

      final response = await PushTokenRepository.delete(
        accessToken: accessToken,
        token: token,
      );

      debugPrint('FCM push token delete success: ${response.success}');
    } catch (e, stack) {
      debugPrint('FCM push token delete failed: $e');
      debugPrint('$stack');
    }
  }

  static Future<bool> ensureGrantedForReminder(BuildContext context) async {
    final currentSettings = await _messaging.getNotificationSettings();
    if (_isGranted(currentSettings.authorizationStatus)) {
      return true;
    }

    debugPrint(
      'FCM reminder checkbox tapped while permission denied: '
      '${currentSettings.authorizationStatus}',
    );

    if (!context.mounted) return false;

    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('알림 권한이 필요해요'),
          content: const Text('예약 알림을 받으려면 알림 권한을 허용해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('허용하기'),
            ),
          ],
        );
      },
    );

    if (shouldRequest != true) {
      debugPrint('FCM skipped reminder API call due to missing permission');
      return false;
    }

    final requestedSettings = await _messaging.requestPermission();
    if (_isGranted(requestedSettings.authorizationStatus)) {
      debugPrint('FCM permission granted after checkbox-triggered flow');
      return true;
    }

    debugPrint(
      'FCM skipped reminder API call due to missing permission: '
      '${requestedSettings.authorizationStatus}',
    );
    return false;
  }

  static bool _isGranted(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  static String get _currentPlatform {
    if (Platform.isIOS) return 'IOS';
    return 'ANDROID';
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    final notification = message.notification;
    if (context == null || notification == null) {
      debugPrint('FCM foreground message received: ${message.messageId}');
      return;
    }

    final parts = <String>[
      if ((notification.title ?? '').isNotEmpty) notification.title!,
      if ((notification.body ?? '').isNotEmpty) notification.body!,
    ];
    if (parts.isEmpty) return;

    showTopAppSnackBar(context, parts.join('\n'));
  }

  static void _handleOpenedMessage(RemoteMessage message) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('FCM opened message received: ${message.messageId}');
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}
