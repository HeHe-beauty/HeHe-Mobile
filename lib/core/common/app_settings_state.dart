import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSettingsState {
  static const _storage = FlutterSecureStorage();
  static const _themeModeKey = 'settings.themeMode';
  static const _pushEnabledKey = 'settings.pushEnabled';
  static const _nightPushEnabledKey = 'settings.nightPushEnabled';
  static const _marketingEnabledKey = 'settings.marketingEnabled';
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
  static bool _pendingPushEnableFromSettings = false;

  static bool get isDarkMode => themeMode.value == ThemeMode.dark;

  static Future<void> restore() async {
    final savedThemeMode = await _storage.read(key: _themeModeKey);
    final savedPushEnabled = await _storage.read(key: _pushEnabledKey);
    final savedNightPushEnabled = await _storage.read(
      key: _nightPushEnabledKey,
    );
    final savedMarketingEnabled = await _storage.read(
      key: _marketingEnabledKey,
    );

    themeMode.value = savedThemeMode == _darkThemeValue
        ? ThemeMode.dark
        : ThemeMode.light;
    pushEnabled.value = savedPushEnabled != 'false';
    nightPushEnabled.value =
        pushEnabled.value && savedNightPushEnabled == _trueValue;
    marketingEnabled.value = savedMarketingEnabled == _trueValue;
  }

  static Future<void> syncNotificationPermissionGranted({
    required bool granted,
  }) async {
    final savedPushEnabled = await _storage.read(key: _pushEnabledKey);
    final savedNightPushEnabled = await _storage.read(
      key: _nightPushEnabledKey,
    );
    final savedMarketingEnabled = await _storage.read(
      key: _marketingEnabledKey,
    );

    final nextPushEnabled =
        granted &&
        (_pendingPushEnableFromSettings || savedPushEnabled != 'false');
    pushEnabled.value = nextPushEnabled;
    await _writeBool(_pushEnabledKey, nextPushEnabled);

    final nextNightPushEnabled =
        nextPushEnabled && savedNightPushEnabled == _trueValue;
    nightPushEnabled.value = nextNightPushEnabled;
    await _writeBool(_nightPushEnabledKey, nextNightPushEnabled);

    final nextMarketingEnabled =
        nextPushEnabled && savedMarketingEnabled == _trueValue;
    marketingEnabled.value = nextMarketingEnabled;
    await _writeBool(_marketingEnabledKey, nextMarketingEnabled);

    _pendingPushEnableFromSettings = false;
  }

  static void setPushEnabled(bool value) {
    pushEnabled.value = value;
    _writeBool(_pushEnabledKey, value);

    if (!value) {
      nightPushEnabled.value = false;
      _writeBool(_nightPushEnabledKey, false);
      marketingEnabled.value = false;
      _writeBool(_marketingEnabledKey, false);
    }
  }

  static void setNightPushEnabled(bool value) {
    if (!pushEnabled.value) return;
    nightPushEnabled.value = value;
    _writeBool(_nightPushEnabledKey, value);
  }

  static void setMarketingEnabled(bool value) {
    marketingEnabled.value = value;
    _writeBool(_marketingEnabledKey, value);
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

  static void markPendingPushEnableFromSettings() {
    _pendingPushEnableFromSettings = true;
  }

  static Future<void> _writeBool(String key, bool value) {
    return _storage.write(key: key, value: value ? _trueValue : 'false');
  }
}
