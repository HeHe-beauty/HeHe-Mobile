import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class MapCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final double size;

  const MapCircleButton({
    super.key,
    required this.onTap,
    required this.child,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
