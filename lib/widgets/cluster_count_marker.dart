import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class ClusterCountMarker extends StatelessWidget {
  static const double singleDefaultSize = 30;
  static const double singleSelectedSize = 38;

  final int count;
  final bool isSelected;
  final bool isSingle;

  const ClusterCountMarker({
    super.key,
    required this.count,
    this.isSelected = false,
    this.isSingle = false,
  });

  double get _size {
    if (isSingle) {
      return isSelected ? singleSelectedSize : singleDefaultSize;
    }

    final scaledSize = 68 + (((count - 2).clamp(0, 48) / 3) * 5.0);
    return scaledSize.clamp(68.0, 128.0);
  }

  double get _fontSize {
    final scaledSize = 20 + (((count - 2).clamp(0, 48) / 3) * 0.55);
    return scaledSize.clamp(20.0, 29.0);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = _size;

    final _MarkerTone tone = _resolveTone(
      palette: palette,
      isDark: isDark,
      isSelected: isSelected,
      isSingle: isSingle,
    );

    if (isSingle) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tone.gradient,
          ),
          border: tone.borderColor == null
              ? null
              : Border.all(
                  color: tone.borderColor!,
                  width: isSelected ? 3.2 : 2,
                ),
          boxShadow: [
            BoxShadow(
              color: tone.shadowColor,
              blurRadius: isSelected ? 17 : 9,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: isSelected ? 11 : 8,
            height: isSelected ? 11 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone.dotColor,
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tone.gradient,
        ),
        border: tone.borderColor == null
            ? null
            : Border.all(
                color: tone.borderColor!,
                width: isSelected ? 3.4 : 2.4,
              ),
        boxShadow: [
          BoxShadow(
            color: tone.shadowColor,
            blurRadius: isSelected ? 15 : 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$count',
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.w900,
            color: tone.textColor,
            letterSpacing: -0.5,
            height: 1,
            shadows: isDark
                ? const []
                : [
                    Shadow(
                      color: palette.textPrimary.withValues(
                        alpha: isSelected ? 0.14 : 0.08,
                      ),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  _MarkerTone _resolveTone({
    required AppPalette palette,
    required bool isDark,
    required bool isSelected,
    required bool isSingle,
  }) {
    if (isDark) {
      if (isSelected) {
        if (isSingle) {
          return _MarkerTone(
            gradient: [
              palette.mapMarkerDarkSelectedStart,
              palette.primaryStrong,
            ],
            borderColor: null,
            shadowColor: palette.primary.withValues(alpha: 0.34),
            textColor: Colors.white,
            dotColor: Colors.white,
          );
        }

        return _MarkerTone(
          gradient: [
            palette.mapMarkerDarkSelectedStart.withValues(alpha: 0.88),
            palette.primary.withValues(alpha: 0.78),
          ],
          borderColor: null,
          shadowColor: palette.primary.withValues(alpha: 0.2),
          textColor: Colors.white,
          dotColor: Colors.white,
        );
      }

      if (isSingle) {
        return _MarkerTone(
          gradient: [palette.mapMarkerDarkStart, palette.mapMarkerDarkEnd],
          borderColor: null,
          shadowColor: palette.primary.withValues(alpha: 0.24),
          textColor: Colors.white,
          dotColor: Colors.white,
        );
      }

      return _MarkerTone(
        gradient: [
          palette.mapMarkerDarkStart.withValues(alpha: 0.72),
          palette.mapMarkerDarkEnd.withValues(alpha: 0.62),
        ],
        borderColor: null,
        shadowColor: palette.primary.withValues(alpha: 0.12),
        textColor: Colors.white,
        dotColor: Colors.white,
      );
    }

    if (isSelected) {
      if (isSingle) {
        return _MarkerTone(
          gradient: [
            palette.mapMarkerLightSelectedStart,
            palette.primaryStrong,
          ],
          borderColor: palette.surface.withValues(alpha: 0.98),
          shadowColor: palette.primary.withValues(alpha: 0.28),
          textColor: palette.surface,
          dotColor: palette.surface.withValues(alpha: 0.98),
        );
      }

      return _MarkerTone(
        gradient: [
          palette.mapMarkerLightSelectedStart.withValues(alpha: 0.9),
          palette.primary.withValues(alpha: 0.78),
        ],
        borderColor: palette.surface.withValues(alpha: 0.82),
        shadowColor: palette.primary.withValues(alpha: 0.18),
        textColor: palette.surface,
        dotColor: palette.surface.withValues(alpha: 0.78),
      );
    }

    if (isSingle) {
      return _MarkerTone(
        gradient: [palette.mapMarkerLightStart, palette.mapMarkerLightEnd],
        borderColor: palette.surface.withValues(alpha: 0.94),
        shadowColor: palette.primary.withValues(alpha: 0.2),
        textColor: palette.surface,
        dotColor: palette.surface.withValues(alpha: 0.96),
      );
    }

    return _MarkerTone(
      gradient: [
        palette.mapMarkerLightStart.withValues(alpha: 0.74),
        palette.mapMarkerLightEnd.withValues(alpha: 0.64),
      ],
      borderColor: palette.surface.withValues(alpha: 0.58),
      shadowColor: palette.primary.withValues(alpha: 0.1),
      textColor: palette.surface,
      dotColor: palette.surface.withValues(alpha: 0.7),
    );
  }
}

class _MarkerTone {
  final List<Color> gradient;
  final Color? borderColor;
  final Color shadowColor;
  final Color textColor;
  final Color dotColor;

  const _MarkerTone({
    required this.gradient,
    required this.borderColor,
    required this.shadowColor,
    required this.textColor,
    required this.dotColor,
  });
}
