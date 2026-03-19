import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class ClusterCountMarker extends StatelessWidget {
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
    if (isSingle) return isSelected ? 30 : 24;
    if (count >= 100) return 78;
    if (count >= 10) return 68;
    return 60;
  }

  double get _fontSize {
    if (count >= 100) return 24;
    if (count >= 10) return 22;
    return 21;
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
          border: Border.all(
            color: tone.borderColor,
            width: isSelected ? 3.4 : 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: tone.shadowColor,
              blurRadius: isSelected ? 15 : 7,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: isSelected ? 9 : 7,
            height: isSelected ? 9 : 7,
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
        border: Border.all(
          color: tone.borderColor,
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.17,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tone.dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: size * 0.34,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.w900,
                color: tone.textColor,
                letterSpacing: -0.5,
                height: 1,
                shadows: [
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
        ],
      ),
    );
  }

  _MarkerTone _resolveTone({
    required AppPalette palette,
    required bool isDark,
    required bool isSelected,
  }) {
    if (isDark) {
      if (isSelected) {
        return _MarkerTone(
          gradient: [palette.mapMarkerDarkSelectedStart, palette.primary],
          borderColor: palette.surface.withValues(alpha: 0.92),
          shadowColor: palette.primary.withValues(alpha: 0.34),
          textColor: palette.surface,
          dotColor: palette.surface.withValues(alpha: 0.95),
        );
      }

      return _MarkerTone(
        gradient: [palette.mapMarkerDarkStart, palette.mapMarkerDarkEnd],
        borderColor: palette.surface.withValues(alpha: 0.55),
        shadowColor: palette.textPrimary.withValues(alpha: 0.16),
        textColor: palette.textPrimary,
        dotColor: palette.surface.withValues(alpha: 0.74),
      );
    }

    if (isSelected) {
      return _MarkerTone(
        gradient: [palette.mapMarkerLightSelectedStart, palette.primary],
        borderColor: palette.surface.withValues(alpha: 0.98),
        shadowColor: palette.textPrimary.withValues(alpha: 0.14),
        textColor: palette.surface,
        dotColor: palette.surface.withValues(alpha: 0.98),
      );
    }

    return _MarkerTone(
      gradient: [palette.mapMarkerLightStart, palette.mapMarkerLightEnd],
      borderColor: palette.surface.withValues(alpha: 0.72),
      shadowColor: palette.textPrimary.withValues(alpha: 0.08),
      textColor: palette.surface.withValues(alpha: 0.96),
      dotColor: palette.surface.withValues(alpha: 0.82),
    );
  }
}

class _MarkerTone {
  final List<Color> gradient;
  final Color borderColor;
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
