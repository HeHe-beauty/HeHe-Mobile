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
  final bool showSummary;
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
    this.showSummary = true,
    this.maxVisibleItems = 3,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final visibleReservations = reservations.take(maxVisibleItems).toList();
    final innerCardColor = palette.surfaceSoft;

    if (isLoginRequired) {
      return _LoginReservationPrompt(onTap: onTapCard);
    }

    return SectionLikeCard(
      onTap: onTapCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSummary) ...[
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onTapSummary,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: innerCardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
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
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
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
                                          fontSize: 13,
                                          color: palette.textSecondary,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (onTapSummary != null) ...[
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
          ],
          if (visibleReservations.isEmpty && !showSummary)
            const _EmptyReservationState()
          else if (visibleReservations.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reservationSectionLabel != null) ...[
                  Text(
                    reservationSectionLabel!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
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
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LoginReservationPrompt extends StatelessWidget {
  final VoidCallback? onTap;

  const _LoginReservationPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final innerCardColor = palette.surfaceSoft;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: innerCardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '로그인하고 다가오는 예약 일정 확인하기',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: palette.primary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    weight: 700,
                    color: palette.primary,
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

class _UpcomingReservationRow extends StatelessWidget {
  final CalendarCardReservationItem item;

  const _UpcomingReservationRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final innerCardColor = palette.surfaceSoft;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: innerCardColor,
            borderRadius: BorderRadius.circular(14),
          ),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.dateLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
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
  const _EmptyReservationState();

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
        '다가오는 예약이 없어요. 다음 방문 일정을 추가해보세요.',
        style: TextStyle(
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w400,
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
      color: palette.primary,
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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
            border: Border.all(
              color: palette.primaryStrong.withValues(alpha: 0.34),
            ),
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
                    color: palette.primaryStrong,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: palette.primaryStrong,
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
