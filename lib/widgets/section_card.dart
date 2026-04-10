import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final VoidCallback? onTapMore;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.onTapMore,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: palette.shadow,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              if (onTapMore != null)
                InkWell(
                  onTap: onTapMore,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 28,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
