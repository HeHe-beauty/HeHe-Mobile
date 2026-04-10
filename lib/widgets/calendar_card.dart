import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class CalendarCardReservationItem {
  final String title;
  final String dateLabel;
  final String? dDayLabel;
  final VoidCallback? onTap;

  const CalendarCardReservationItem({
    required this.title,
    required this.dateLabel,
    this.dDayLabel,
    this.onTap,
  });
}

class CalendarCard extends StatelessWidget {
  final String title;
  final String? dDayLabel;
  final String? subtitle;
  final String? reservationSectionLabel;
  final List<CalendarCardReservationItem> reservations;
  final VoidCallback? onTapCalendar;
  final VoidCallback? onTapStart;
  final VoidCallback? onTapCard;
  final VoidCallback? onTapSummary;
  final bool isLoginRequired;
  final bool showAddButton;
  final int maxVisibleItems;

  const CalendarCard({
    super.key,
    required this.title,
    this.dDayLabel,
    this.subtitle,
    this.reservationSectionLabel,
    required this.reservations,
    this.onTapCalendar,
    this.onTapStart,
    this.onTapCard,
    this.onTapSummary,
    this.isLoginRequired = false,
    this.showAddButton = true,
    this.maxVisibleItems = 3,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final visibleReservations = reservations.take(maxVisibleItems).toList();

    return SectionLikeCard(
      onTap: onTapCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTapSummary,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: palette.textPrimary,
                            ),
                          ),
                          if (dDayLabel != null || subtitle != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (dDayLabel != null)
                                  Text(
                                    dDayLabel!,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                      color: palette.primaryStrong,
                                    ),
                                  ),
                                if (dDayLabel != null && subtitle != null)
                                  const SizedBox(width: 10),
                                if (subtitle != null)
                                  Expanded(
                                    child: Text(
                                      subtitle!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: palette.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isLoginRequired || onTapSummary != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: palette.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (visibleReservations.isEmpty)
            _EmptyReservationState(isLoginRequired: isLoginRequired)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reservationSectionLabel != null) ...[
                  Text(
                    reservationSectionLabel!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                for (var i = 0; i < visibleReservations.length; i++) ...[
                  _UpcomingReservationRow(item: visibleReservations[i]),
                  if (i != visibleReservations.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          if (showAddButton) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _PrimaryButton(label: '일정 추가하기', onTap: onTapStart),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SecondaryButton(
                    label: '캘린더 바로가기',
                    onTap: onTapCalendar,
                  ),
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
  final VoidCallback? onTap;

  const SectionLikeCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
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
        ),
      ),
    );
  }
}

class _UpcomingReservationRow extends StatelessWidget {
  final CalendarCardReservationItem item;

  const _UpcomingReservationRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surfaceSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.dateLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.dDayLabel != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.dDayLabel!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: palette.primaryStrong,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyReservationState extends StatelessWidget {
  final bool isLoginRequired;

  const _EmptyReservationState({required this.isLoginRequired});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        isLoginRequired
            ? '로그인 후 다가오는 예약 일정을 확인할 수 있어요.'
            : '다가오는 예약이 없어요. 다음 방문 일정을 추가해보세요.',
        style: TextStyle(
          fontSize: 11,
          height: 1.45,
          fontWeight: FontWeight.w700,
          color: palette.textSecondary,
        ),
      ),
    );
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
                fontSize: 12,
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

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SecondaryButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.primary.withValues(alpha: 0.22)),
            color: palette.primarySoft.withValues(alpha: 0.28),
          ),
          child: SizedBox(
            height: 46,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 15,
                    color: palette.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: palette.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
