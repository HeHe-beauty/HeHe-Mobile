import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

class SelectedHospitalMarker extends StatelessWidget {
  static const double width = 190;
  static const double height = 86;

  final String name;

  const SelectedHospitalMarker({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 42,
                padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: palette.primary.withValues(alpha: 0.16),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                    BoxShadow(
                      color: palette.textPrimary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            palette.mapMarkerLightSelectedStart,
                            palette.primary,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.local_hospital_rounded,
                        size: 16,
                        color: palette.surface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: SizedBox(
                        height: 28,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            strutStyle: const StrutStyle(
                              fontSize: 13,
                              height: 1,
                              forceStrutHeight: true,
                            ),
                            style: AppTextStyles.homeBodyStrong.copyWith(
                              color: palette.textPrimary,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            child: Container(
              width: 2,
              height: 25,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.mapMarkerLightSelectedStart, palette.primary],
              ),
              border: Border.all(color: palette.surface, width: 3),
              boxShadow: [
                BoxShadow(
                  color: palette.primary.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
