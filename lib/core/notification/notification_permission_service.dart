import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/push_token/push_token_repository.dart';
import '../../screens/home_screen.dart';
import '../auth/auth_state.dart';
import '../common/app_settings_state.dart';

class NotificationPermissionService {
  const NotificationPermissionService._();

  static const AndroidNotificationChannel _androidNotificationChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'HeHe push notifications',
        importance: Importance.max,
      );

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  static StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;
  static bool _isLocalNotificationsInitialized = false;
  static int _notificationId = 0;

  static Future<void> initializeForAppStart() async {
    await _initializeLocalNotifications();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

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
    ) async {
      await _handleForegroundMessage(message);
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

  static Future<bool> ensureGrantedForSettings(BuildContext context) async {
    final currentSettings = await _messaging.getNotificationSettings();
    if (_isGranted(currentSettings.authorizationStatus)) {
      return true;
    }

    if (!context.mounted) return false;

    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('알림 권한이 필요해요'),
          content: const Text('알림 설정을 사용하려면 알림 권한을 허용해주세요.'),
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
      return false;
    }

    final requestedSettings = await _messaging.requestPermission();
    return _isGranted(requestedSettings.authorizationStatus);
  }

  static bool _isGranted(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  static String get _currentPlatform {
    if (Platform.isIOS) return 'IOS';
    return 'ANDROID';
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? _stringData(message.data['title']);
    final body = notification?.body ?? _stringData(message.data['body']);

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    await _localNotifications.show(
      id: _notificationId++,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidNotificationChannel.id,
          _androidNotificationChannel.name,
          channelDescription: _androidNotificationChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'home',
    );
  }

  static String? _stringData(Object? value) {
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static void _handleOpenedMessage(RemoteMessage message) {
    _routeToHome();
  }

  static Future<void> _initializeLocalNotifications() async {
    if (_isLocalNotificationsInitialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) => _routeToHome(),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidNotificationChannel);

    _isLocalNotificationsInitialized = true;
  }

  static void _routeToHome() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}
