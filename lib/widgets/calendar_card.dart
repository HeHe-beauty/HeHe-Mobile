import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class CalendarCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int selectedDay;
  final List<int> days;
  final VoidCallback? onTapCalendar;
  final VoidCallback? onTapRecord;
  final VoidCallback? onTapStart;
  final bool isLoginRequired;
  final bool showAddButton;

  const CalendarCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selectedDay,
    required this.days,
    this.onTapCalendar,
    this.onTapRecord,
    this.onTapStart,
    this.isLoginRequired = false,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SectionLikeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: palette.textPrimary,
                      ),
                    ),
                    if (!isLoginRequired) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: palette.surfaceSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Icon(
                          Icons.sync_rounded,
                          size: 16,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: onTapCalendar,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 28,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: palette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _MiniWeekRow(days: days, selectedDay: selectedDay),
          if (showAddButton) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: _PrimaryButton(label: '일정 추가하기', onTap: onTapStart),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class SectionLikeCard extends StatelessWidget {
  final Widget child;
  const SectionLikeCard({super.key, required this.child});

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
      child: child,
    );
  }
}

class _MiniWeekRow extends StatelessWidget {
  final List<int> days;
  final int selectedDay;

  const _MiniWeekRow({required this.days, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        for (final d in days) ...[
          Expanded(
            child: Column(
              children: [
                Text(
                  _weekdayLabelFor(d, days.first),
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textTertiary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: d == selectedDay
                        ? palette.primaryStrong
                        : palette.surface.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      '$d',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: d == selectedDay
                            ? palette.surface
                            : palette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _weekdayLabelFor(int day, int start) {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    return labels[(day - start) % 7];
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PrimaryButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.primarySoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 46,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: palette.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
