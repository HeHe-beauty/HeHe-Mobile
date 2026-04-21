import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class CurrentLocationMarker extends StatelessWidget {
  const CurrentLocationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      width: 34,
      height: 34,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primaryStrong.withValues(alpha: 0.16),
                border: Border.all(
                  color: palette.primaryStrong.withValues(alpha: 0.34),
                  width: 1.25,
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primaryStrong,
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.surface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
