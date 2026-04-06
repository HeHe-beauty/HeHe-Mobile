import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class AppIconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double size;
  final double iconSize;
  final bool showBorder;
  final bool showShadow;

  const AppIconCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.backgroundColor,
    this.size = 52,
    this.iconSize = 24,
    this.showBorder = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: backgroundColor ?? palette.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: showBorder ? Border.all(color: palette.border) : null,
            boxShadow: [
              if (showShadow)
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Icon(icon, size: iconSize, color: palette.icon),
        ),
      ),
    );
  }
}
