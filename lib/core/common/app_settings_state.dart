import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSettingsState {
  static const _storage = FlutterSecureStorage();
  static const _themeModeKey = 'settings.themeMode';
  static const _pushEnabledKey = 'settings.pushEnabled';
  static const _nightPushEnabledKey = 'settings.nightPushEnabled';
  static const _marketingEnabledKey = 'settings.marketingEnabled';
  static const _darkThemeValue = 'dark';
  static const _lightThemeValue = 'light';
  static const _trueValue = 'true';

  static final ValueNotifier<bool> pushEnabled = ValueNotifier(false);
  static final ValueNotifier<bool> nightPushEnabled = ValueNotifier(false);
  static final ValueNotifier<bool> marketingEnabled = ValueNotifier(false);
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.light,
  );

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
    pushEnabled.value = savedPushEnabled == _trueValue;
    nightPushEnabled.value =
        pushEnabled.value && savedNightPushEnabled == _trueValue;
    marketingEnabled.value = savedMarketingEnabled == _trueValue;
  }

  static Future<void> syncNotificationPermissionGranted({
    required bool granted,
  }) async {
    // Operating-system permission must never opt a user in by itself. It only
    // turns an existing push preference off when the permission is revoked.
    final nextPushEnabled = granted ? pushEnabled.value : false;
    await _setBoolValue(pushEnabled, _pushEnabledKey, nextPushEnabled);

    final nextNightPushEnabled = nextPushEnabled && nightPushEnabled.value;
    await _setBoolValue(
      nightPushEnabled,
      _nightPushEnabledKey,
      nextNightPushEnabled,
    );

    final nextMarketingEnabled = nextPushEnabled && marketingEnabled.value;
    await _setBoolValue(
      marketingEnabled,
      _marketingEnabledKey,
      nextMarketingEnabled,
    );
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

  static Future<void> _writeBool(String key, bool value) {
    return _storage.write(key: key, value: value ? _trueValue : 'false');
  }

  static Future<void> _setBoolValue(
    ValueNotifier<bool> notifier,
    String key,
    bool value,
  ) {
    if (notifier.value == value) {
      return Future.value();
    }

    notifier.value = value;
    return _writeBool(key, value);
  }
}
