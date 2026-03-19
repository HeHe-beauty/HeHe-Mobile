import 'package:flutter/material.dart';
import 'app_palette.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppPalette.light.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.light.primary,
      brightness: Brightness.light,
    ),
    extensions: const [
      AppPalette.light,
    ],
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppPalette.dark.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.dark.primary,
      brightness: Brightness.dark,
    ),
    extensions: const [
      AppPalette.dark,
    ],
  );
}