import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'map_control_surface.dart';

class MapCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final double size;

  const MapCircleButton({
    super.key,
    required this.onTap,
    required this.child,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(kMapControlRadius),
      elevation: 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(kMapControlRadius),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kMapControlRadius),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
