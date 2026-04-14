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
    this.size = 44,
    this.iconSize = 18,
    this.showBorder = false,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: backgroundColor ?? palette.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: showShadow ? 0.5 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: showBorder ? Border.all(color: palette.border) : null,
          ),
          child: Icon(icon, size: iconSize, color: palette.icon),
        ),
      ),
    );
  }
}
