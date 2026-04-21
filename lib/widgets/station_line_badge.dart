import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class StationLineBadge extends StatelessWidget {
  final String line;

  const StationLineBadge({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border.withValues(alpha: 0.85)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          line,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: palette.primaryStrong,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
