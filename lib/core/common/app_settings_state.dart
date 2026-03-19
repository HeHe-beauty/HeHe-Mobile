import 'package:flutter/material.dart';

class AppSettingsState {
  static final ValueNotifier<bool> pushEnabled = ValueNotifier(true);
  static final ValueNotifier<bool> nightPushEnabled = ValueNotifier(false);
  static final ValueNotifier<bool> marketingEnabled = ValueNotifier(false);
  static final ValueNotifier<ThemeMode> themeMode =
  ValueNotifier(ThemeMode.light);

  static bool get isDarkMode => themeMode.value == ThemeMode.dark;

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
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}