import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSettingsState {
  static const _storage = FlutterSecureStorage();
  static const _themeModeKey = 'settings.themeMode';
  static const _notificationPermissionRequestedKey =
      'settings.notificationPermissionRequested';
  static const _darkThemeValue = 'dark';
  static const _lightThemeValue = 'light';
  static const _trueValue = 'true';

  static final ValueNotifier<bool> pushEnabled = ValueNotifier(true);
  static final ValueNotifier<bool> nightPushEnabled = ValueNotifier(false);
  static final ValueNotifier<bool> marketingEnabled = ValueNotifier(false);
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.light,
  );

  static bool get isDarkMode => themeMode.value == ThemeMode.dark;

  static Future<void> restore() async {
    final savedThemeMode = await _storage.read(key: _themeModeKey);
    themeMode.value = savedThemeMode == _darkThemeValue
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  static void setPushEnabled(bool value) {
    pushEnabled.value = value;

    if (!value) {
      nightPushEnabled.value = false;
    }
  }

  static void setNightPushEnabled(bool value) {
    if (!pushEnabled.value) return;
    nightPushEnabled.value = value;
  }

  static void setMarketingEnabled(bool value) {
    marketingEnabled.value = value;
  }

  static void setDarkMode(bool isDark) {
    final nextThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    themeMode.value = nextThemeMode;
    _storage.write(
      key: _themeModeKey,
      value: isDark ? _darkThemeValue : _lightThemeValue,
    );
  }

  static Future<bool> hasRequestedNotificationPermission() async {
    final value = await _storage.read(key: _notificationPermissionRequestedKey);
    return value == _trueValue;
  }

  static Future<void> markNotificationPermissionRequested() {
    return _storage.write(
      key: _notificationPermissionRequestedKey,
      value: _trueValue,
    );
  }
}
