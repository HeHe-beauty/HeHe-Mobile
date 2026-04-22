import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

const double kMapControlRadius = 14;

BoxDecoration mapControlDecoration(BuildContext context) {
  final palette = context.palette;

  return BoxDecoration(
    color: palette.surface,
    borderRadius: BorderRadius.circular(kMapControlRadius),
    boxShadow: [
      BoxShadow(
        color: palette.shadow,
        blurRadius: 1,
        offset: const Offset(0, 0.5),
      ),
    ],
  );
}
