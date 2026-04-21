import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color surface;
  final Color surfaceSoft;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color primary;
  final Color primarySoft;
  final Color primaryStrong;
  final Color icon;
  final Color shadow;
  final Color scrim;
  final Color modalBarrier;
  final Color bottomSheetSurface;
  final Color bottomSheetInnerSurface;
  final Color bottomSheetBorder;
  final Color bottomSheetChipSurface;
  final Color bottomSheetChipBorder;
  final Color mapMarkerLightStart;
  final Color mapMarkerLightEnd;
  final Color mapMarkerLightSelectedStart;
  final Color mapMarkerDarkStart;
  final Color mapMarkerDarkEnd;
  final Color mapMarkerDarkSelectedStart;
  final Color kakaoBackground;
  final Color kakaoForeground;
  final Color naverBackground;
  final Color naverOverlay;
  final Color splashDarkBackground;
  final Color splashDarkGradientStart;
  final Color splashDarkGradientMiddle;
  final Color splashDarkGradientEnd;
  final Color splashDarkOrbPrimary;
  final Color splashDarkOrbSecondary;
  final Color splashDarkOrbTertiary;
  final Color danger;
  final Color success;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceSoft,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.primarySoft,
    required this.primaryStrong,
    required this.icon,
    required this.shadow,
    required this.scrim,
    required this.modalBarrier,
    required this.bottomSheetSurface,
    required this.bottomSheetInnerSurface,
    required this.bottomSheetBorder,
    required this.bottomSheetChipSurface,
    required this.bottomSheetChipBorder,
    required this.mapMarkerLightStart,
    required this.mapMarkerLightEnd,
    required this.mapMarkerLightSelectedStart,
    required this.mapMarkerDarkStart,
    required this.mapMarkerDarkEnd,
    required this.mapMarkerDarkSelectedStart,
    required this.kakaoBackground,
    required this.kakaoForeground,
    required this.naverBackground,
    required this.naverOverlay,
    required this.splashDarkBackground,
    required this.splashDarkGradientStart,
    required this.splashDarkGradientMiddle,
    required this.splashDarkGradientEnd,
    required this.splashDarkOrbPrimary,
    required this.splashDarkOrbSecondary,
    required this.splashDarkOrbTertiary,
    required this.danger,
    required this.success,
  });

  static const light = AppPalette(
    bg: Color(0xFFF6F7FB),
    surface: Colors.white,
    surfaceSoft: Color(0xFFF7F8FC),
    surfaceMuted: Color(0xFFEFF2FF),
    border: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    primary: Color(0xFF4E63F5),
    primarySoft: Color(0xFFE4E8FF),
    primaryStrong: Color(0xFF2E43D6),
    icon: Color(0xFF111827),
    shadow: Color(0x0A000000),
    scrim: Color(0x1F000000),
    modalBarrier: Color(0x26000000),
    bottomSheetSurface: Color(0xFFF7F8FC),
    bottomSheetInnerSurface: Color(0xFFFFFFFF),
    bottomSheetBorder: Color(0xFFE5E7EB),
    bottomSheetChipSurface: Color(0xFFFFFFFF),
    bottomSheetChipBorder: Color(0xFFE5E7EB),
    mapMarkerLightStart: Color(0xFF7EA4FF),
    mapMarkerLightEnd: Color(0xFF4E73F5),
    mapMarkerLightSelectedStart: Color(0xFF617CFF),
    mapMarkerDarkStart: Color(0xFF6F8DFF),
    mapMarkerDarkEnd: Color(0xFF4B66DB),
    mapMarkerDarkSelectedStart: Color(0xFF8EA2FF),
    kakaoBackground: Color(0xFFFEE500),
    kakaoForeground: Color(0xFF191919),
    naverBackground: Color(0xFF03C75A),
    naverOverlay: Color(0x3DFFFFFF),
    splashDarkBackground: Color(0xFF020B22),
    splashDarkGradientStart: Color(0xFF0A2A60),
    splashDarkGradientMiddle: Color(0xFF02163F),
    splashDarkGradientEnd: Color(0xFF010B24),
    splashDarkOrbPrimary: Color(0xFF5A86FF),
    splashDarkOrbSecondary: Color(0xFF3E6BFF),
    splashDarkOrbTertiary: Color(0xFF243E8F),
    danger: Color(0xFFFF5A5F),
    success: Color(0xFF18B26B),
  );

  static const dark = AppPalette(
    bg: Color(0xFF101318),
    surface: Color(0xFF181C23),
    surfaceSoft: Color(0xFF20252E),
    surfaceMuted: Color(0xFF273044),
    border: Color(0xFF323946),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFFC1C7D0),
    textTertiary: Color(0xFF8E97A6),
    primary: Color(0xFF2534B8),
    primarySoft: Color(0xFF161E55),
    primaryStrong: Color(0xFFB8C2FF),
    icon: Color(0xFFF3F4F6),
    shadow: Color(0x52000000),
    scrim: Color(0x7A000000),
    modalBarrier: Color(0x99000000),
    bottomSheetSurface: Color(0xFF161A21),
    bottomSheetInnerSurface: Color(0xFF20252E),
    bottomSheetBorder: Color(0xFF343B49),
    bottomSheetChipSurface: Color(0xFF252B36),
    bottomSheetChipBorder: Color(0xFF465064),
    mapMarkerLightStart: Color(0xFF7EA4FF),
    mapMarkerLightEnd: Color(0xFF4E73F5),
    mapMarkerLightSelectedStart: Color(0xFF617CFF),
    mapMarkerDarkStart: Color(0xFF6F8DFF),
    mapMarkerDarkEnd: Color(0xFF4B66DB),
    mapMarkerDarkSelectedStart: Color(0xFF8EA2FF),
    kakaoBackground: Color(0xFFFEE500),
    kakaoForeground: Color(0xFF191919),
    naverBackground: Color(0xFF03C75A),
    naverOverlay: Color(0x3DFFFFFF),
    splashDarkBackground: Color(0xFF020B22),
    splashDarkGradientStart: Color(0xFF0A2A60),
    splashDarkGradientMiddle: Color(0xFF02163F),
    splashDarkGradientEnd: Color(0xFF010B24),
    splashDarkOrbPrimary: Color(0xFF5A86FF),
    splashDarkOrbSecondary: Color(0xFF3E6BFF),
    splashDarkOrbTertiary: Color(0xFF243E8F),
    danger: Color(0xFFFF7B85),
    success: Color(0xFF32D39A),
  );

  @override
  ThemeExtension<AppPalette> copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceSoft,
    Color? surfaceMuted,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? primary,
    Color? primarySoft,
    Color? primaryStrong,
    Color? icon,
    Color? shadow,
    Color? scrim,
    Color? modalBarrier,
    Color? bottomSheetSurface,
    Color? bottomSheetInnerSurface,
    Color? bottomSheetBorder,
    Color? bottomSheetChipSurface,
    Color? bottomSheetChipBorder,
    Color? mapMarkerLightStart,
    Color? mapMarkerLightEnd,
    Color? mapMarkerLightSelectedStart,
    Color? mapMarkerDarkStart,
    Color? mapMarkerDarkEnd,
    Color? mapMarkerDarkSelectedStart,
    Color? kakaoBackground,
    Color? kakaoForeground,
    Color? naverBackground,
    Color? naverOverlay,
    Color? splashDarkBackground,
    Color? splashDarkGradientStart,
    Color? splashDarkGradientMiddle,
    Color? splashDarkGradientEnd,
    Color? splashDarkOrbPrimary,
    Color? splashDarkOrbSecondary,
    Color? splashDarkOrbTertiary,
    Color? danger,
    Color? success,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryStrong: primaryStrong ?? this.primaryStrong,
      icon: icon ?? this.icon,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
      modalBarrier: modalBarrier ?? this.modalBarrier,
      bottomSheetSurface: bottomSheetSurface ?? this.bottomSheetSurface,
      bottomSheetInnerSurface:
          bottomSheetInnerSurface ?? this.bottomSheetInnerSurface,
      bottomSheetBorder: bottomSheetBorder ?? this.bottomSheetBorder,
      bottomSheetChipSurface:
          bottomSheetChipSurface ?? this.bottomSheetChipSurface,
      bottomSheetChipBorder:
          bottomSheetChipBorder ?? this.bottomSheetChipBorder,
      mapMarkerLightStart: mapMarkerLightStart ?? this.mapMarkerLightStart,
      mapMarkerLightEnd: mapMarkerLightEnd ?? this.mapMarkerLightEnd,
      mapMarkerLightSelectedStart:
          mapMarkerLightSelectedStart ?? this.mapMarkerLightSelectedStart,
      mapMarkerDarkStart: mapMarkerDarkStart ?? this.mapMarkerDarkStart,
      mapMarkerDarkEnd: mapMarkerDarkEnd ?? this.mapMarkerDarkEnd,
      mapMarkerDarkSelectedStart:
          mapMarkerDarkSelectedStart ?? this.mapMarkerDarkSelectedStart,
      kakaoBackground: kakaoBackground ?? this.kakaoBackground,
      kakaoForeground: kakaoForeground ?? this.kakaoForeground,
      naverBackground: naverBackground ?? this.naverBackground,
      naverOverlay: naverOverlay ?? this.naverOverlay,
      splashDarkBackground: splashDarkBackground ?? this.splashDarkBackground,
      splashDarkGradientStart:
          splashDarkGradientStart ?? this.splashDarkGradientStart,
      splashDarkGradientMiddle:
          splashDarkGradientMiddle ?? this.splashDarkGradientMiddle,
      splashDarkGradientEnd:
          splashDarkGradientEnd ?? this.splashDarkGradientEnd,
      splashDarkOrbPrimary: splashDarkOrbPrimary ?? this.splashDarkOrbPrimary,
      splashDarkOrbSecondary:
          splashDarkOrbSecondary ?? this.splashDarkOrbSecondary,
      splashDarkOrbTertiary:
          splashDarkOrbTertiary ?? this.splashDarkOrbTertiary,
      danger: danger ?? this.danger,
      success: success ?? this.success,
    );
  }

  @override
  ThemeExtension<AppPalette> lerp(
    covariant ThemeExtension<AppPalette>? other,
    double t,
  ) {
    if (other is! AppPalette) return this;

    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primaryStrong: Color.lerp(primaryStrong, other.primaryStrong, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      modalBarrier: Color.lerp(modalBarrier, other.modalBarrier, t)!,
      bottomSheetSurface: Color.lerp(
        bottomSheetSurface,
        other.bottomSheetSurface,
        t,
      )!,
      bottomSheetInnerSurface: Color.lerp(
        bottomSheetInnerSurface,
        other.bottomSheetInnerSurface,
        t,
      )!,
      bottomSheetBorder: Color.lerp(
        bottomSheetBorder,
        other.bottomSheetBorder,
        t,
      )!,
      bottomSheetChipSurface: Color.lerp(
        bottomSheetChipSurface,
        other.bottomSheetChipSurface,
        t,
      )!,
      bottomSheetChipBorder: Color.lerp(
        bottomSheetChipBorder,
        other.bottomSheetChipBorder,
        t,
      )!,
      mapMarkerLightStart: Color.lerp(
        mapMarkerLightStart,
        other.mapMarkerLightStart,
        t,
      )!,
      mapMarkerLightEnd: Color.lerp(
        mapMarkerLightEnd,
        other.mapMarkerLightEnd,
        t,
      )!,
      mapMarkerLightSelectedStart: Color.lerp(
        mapMarkerLightSelectedStart,
        other.mapMarkerLightSelectedStart,
        t,
      )!,
      mapMarkerDarkStart: Color.lerp(
        mapMarkerDarkStart,
        other.mapMarkerDarkStart,
        t,
      )!,
      mapMarkerDarkEnd: Color.lerp(
        mapMarkerDarkEnd,
        other.mapMarkerDarkEnd,
        t,
      )!,
      mapMarkerDarkSelectedStart: Color.lerp(
        mapMarkerDarkSelectedStart,
        other.mapMarkerDarkSelectedStart,
        t,
      )!,
      kakaoBackground: Color.lerp(kakaoBackground, other.kakaoBackground, t)!,
      kakaoForeground: Color.lerp(kakaoForeground, other.kakaoForeground, t)!,
      naverBackground: Color.lerp(naverBackground, other.naverBackground, t)!,
      naverOverlay: Color.lerp(naverOverlay, other.naverOverlay, t)!,
      splashDarkBackground: Color.lerp(
        splashDarkBackground,
        other.splashDarkBackground,
        t,
      )!,
      splashDarkGradientStart: Color.lerp(
        splashDarkGradientStart,
        other.splashDarkGradientStart,
        t,
      )!,
      splashDarkGradientMiddle: Color.lerp(
        splashDarkGradientMiddle,
        other.splashDarkGradientMiddle,
        t,
      )!,
      splashDarkGradientEnd: Color.lerp(
        splashDarkGradientEnd,
        other.splashDarkGradientEnd,
        t,
      )!,
      splashDarkOrbPrimary: Color.lerp(
        splashDarkOrbPrimary,
        other.splashDarkOrbPrimary,
        t,
      )!,
      splashDarkOrbSecondary: Color.lerp(
        splashDarkOrbSecondary,
        other.splashDarkOrbSecondary,
        t,
      )!,
      splashDarkOrbTertiary: Color.lerp(
        splashDarkOrbTertiary,
        other.splashDarkOrbTertiary,
        t,
      )!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
