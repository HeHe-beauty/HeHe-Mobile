import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../common/app_settings_state.dart';

class NotificationPermissionService {
  const NotificationPermissionService._();

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

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
}
