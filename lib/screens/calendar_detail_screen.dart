import 'package:flutter/material.dart';

import '../data/calendar_schedule_store.dart';
import '../models/calendar_schedule.dart';
import '../theme/app_palette.dart';
import '../utils/calendar_schedule_utils.dart';
import '../widgets/visit_schedule_bottom_sheet.dart';

class CalendarDetailScreen extends StatefulWidget {
  final VisitScheduleResult? initialScheduleResult;
  final String? initialScheduleId;

  const CalendarDetailScreen({
    super.key,
    this.initialScheduleResult,
    this.initialScheduleId,
  });

  @override
  State<CalendarDetailScreen> createState() => _CalendarDetailScreenState();
}

class _CalendarDetailScreenState extends State<CalendarDetailScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  final Map<DateTime, List<CalendarSchedule>> _scheduleMap = {};
  bool _didOpenInitialSchedule = false;

  @override
  void initState() {
    super.initState();

    final today = calendarDateOnly(DateTime.now());
    _focusedMonth = DateTime(today.year, today.month, 1);
    _selectedDate = today;
    _refreshSchedules();

    final initialScheduleResult = widget.initialScheduleResult;
    if (initialScheduleResult == null) {
      _openInitialScheduleIfNeeded();
      return;
    }

    final selectedDate = CalendarScheduleStore.upsertFromResult(
      initialScheduleResult,
    );
    _refreshSchedules();
    _focusedMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    _selectedDate = selectedDate;
    _openInitialScheduleIfNeeded();
  }

  void _refreshSchedules() {
    _scheduleMap
      ..clear()
      ..addAll(CalendarScheduleStore.snapshot());
  }

  void _openInitialScheduleIfNeeded() {
    final scheduleId = widget.initialScheduleId;
    if (_didOpenInitialSchedule || scheduleId == null) return;

    final schedule = _findScheduleById(scheduleId);
    if (schedule == null) return;

    _didOpenInitialSchedule = true;
    final targetDate = calendarDateOnly(schedule.dateTime);
    _focusedMonth = DateTime(targetDate.year, targetDate.month, 1);
    _selectedDate = targetDate;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _showScheduleDetailBottomSheet(schedule);
    });
  }

  CalendarSchedule? _findScheduleById(String scheduleId) {
    for (final schedules in _scheduleMap.values) {
      for (final schedule in schedules) {
        if (schedule.id == scheduleId) {
          return schedule;
        }
      }
    }
    return null;
  }

  List<CalendarSchedule> _schedulesFor(DateTime date) {
    return List<CalendarSchedule>.from(
      _scheduleMap[calendarDateOnly(date)] ?? const <CalendarSchedule>[],
    )..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  int _scheduleCountFor(DateTime date) {
    return _scheduleMap[calendarDateOnly(date)]?.length ?? 0;
  }

  List<DateTime> _buildCalendarDates(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final leadingDays = firstDayOfMonth.weekday % 7;
    final startDate = firstDayOfMonth.subtract(Duration(days: leadingDays));

    final dates = <DateTime>[];
    var cursor = startDate;

    while (dates.length < 42) {
      dates.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    return dates;
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      _selectedDate = DateTime(
        _focusedMonth.year,
        _focusedMonth.month,
        _selectedDate.day,
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
      _selectedDate = DateTime(
        _focusedMonth.year,
        _focusedMonth.month,
        _selectedDate.day,
      );
    });
  }

  void _onTapDate(DateTime date) {
    final selectedDate = calendarDateOnly(date);

    setState(() {
      _selectedDate = selectedDate;
      _focusedMonth = DateTime(date.year, date.month, 1);
    });

    _showDateSchedulesBottomSheet(selectedDate);
  }

  Future<void> _showDateSchedulesBottomSheet(DateTime selectedDate) async {
    final palette = context.palette;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: palette.surfaceSoft,
      barrierColor: palette.scrim,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        final schedules = _schedulesFor(selectedDate);

        return _DateSchedulesBottomSheet(
          selectedDate: selectedDate,
          schedules: schedules,
          onTapAdd: () async {
            Navigator.pop(sheetContext);
            await _showScheduleEditorBottomSheet(selectedDate: selectedDate);
            if (!mounted) return;
            await _showDateSchedulesBottomSheet(selectedDate);
          },
          onTapSchedule: (schedule) async {
            Navigator.pop(sheetContext);
            final result = await _showScheduleDetailBottomSheet(schedule);
            if (!mounted ||
                result == _ScheduleDetailSheetResult.deleted ||
                result == _ScheduleDetailSheetResult.closed) {
              return;
            }
            await _showDateSchedulesBottomSheet(selectedDate);
          },
          onTapEdit: (schedule) async {
            Navigator.pop(sheetContext);
            await _showScheduleEditorBottomSheet(initialSchedule: schedule);
            if (!mounted) return;
            await _showDateSchedulesBottomSheet(selectedDate);
          },
        );
      },
    );
  }

  Future<_ScheduleDetailSheetResult> _showScheduleDetailBottomSheet(
    CalendarSchedule schedule,
  ) async {
    final palette = context.palette;

    final result = await showModalBottomSheet<_ScheduleDetailSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: palette.surfaceSoft,
      barrierColor: palette.scrim,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return _CalendarScheduleBottomSheetContent(
              schedule: schedule,
              onTapBack: () {
                Navigator.pop(
                  sheetContext,
                  _ScheduleDetailSheetResult.backToList,
                );
              },
              onTapEdit: () async {
                Navigator.pop(sheetContext, _ScheduleDetailSheetResult.closed);
                await _showScheduleEditorBottomSheet(initialSchedule: schedule);
              },
              onTapDelete: () async {
                Navigator.pop(
                  sheetContext,
                  _ScheduleDetailSheetResult.deleteRequested,
                );
              },
              onChangedThreeDaysBefore: (value) {
                setState(() {
                  schedule.isThreeDaysBefore = value;
                  CalendarScheduleStore.upsert(schedule);
                  _refreshSchedules();
                });
                setModalState(() {});
              },
              onChangedOneDayBefore: (value) {
                setState(() {
                  schedule.isOneDayBefore = value;
                  CalendarScheduleStore.upsert(schedule);
                  _refreshSchedules();
                });
                setModalState(() {});
              },
              onChangedOneHourBefore: (value) {
                setState(() {
                  schedule.isOneHourBefore = value;
                  CalendarScheduleStore.upsert(schedule);
                  _refreshSchedules();
                });
                setModalState(() {});
              },
            );
          },
        );
      },
    );

    if (result == _ScheduleDetailSheetResult.deleteRequested) {
      final shouldDelete = await _showDeleteConfirmDialog();
      if (shouldDelete != true) {
        if (!mounted) return _ScheduleDetailSheetResult.closed;
        return _showScheduleDetailBottomSheet(schedule);
      }

      setState(() {
        CalendarScheduleStore.removeById(schedule.id);
        _refreshSchedules();
      });
      return _ScheduleDetailSheetResult.deleted;
    }

    return result ?? _ScheduleDetailSheetResult.closed;
  }

  Future<bool?> _showDeleteConfirmDialog() {
    final palette = context.palette;

    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) {
        return AlertDialog(
          backgroundColor: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '일정을 삭제할까요?',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: palette.textPrimary,
            ),
          ),
          content: Text(
            '삭제하면 복구할 수 없어요.',
            style: TextStyle(
              color: palette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('취소', style: TextStyle(color: palette.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('삭제', style: TextStyle(color: palette.danger)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showScheduleEditorBottomSheet({
    DateTime? selectedDate,
    CalendarSchedule? initialSchedule,
  }) async {
    final seedDate = initialSchedule?.dateTime ?? selectedDate ?? _selectedDate;
    final fixedDate = initialSchedule == null && selectedDate != null
        ? calendarDateOnly(selectedDate)
        : null;
    final result = await showVisitScheduleBottomSheet(
      context,
      initialDateTime: seedDate,
      fixedDate: fixedDate,
      initialHospitalName: initialSchedule?.hospitalName,
      title: initialSchedule == null ? '일정을 등록할까요?' : '일정을 수정할까요?',
    );

    if (result == null) return;

    final schedule = CalendarSchedule(
      id: initialSchedule?.id ?? CalendarScheduleStore.createId(),
      hospitalName: result.hospitalName.isEmpty
          ? '병원명을 입력해주세요'
          : result.hospitalName,
      dateTime: result.dateTime,
      isThreeDaysBefore: initialSchedule?.isThreeDaysBefore ?? false,
      isOneDayBefore: initialSchedule?.isOneDayBefore ?? false,
      isOneHourBefore: initialSchedule?.isOneHourBefore ?? false,
    );
    final targetDate = calendarDateOnly(result.dateTime);

    setState(() {
      CalendarScheduleStore.upsert(schedule);
      _refreshSchedules();
      _focusedMonth = DateTime(targetDate.year, targetDate.month, 1);
      _selectedDate = targetDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dates = _buildCalendarDates(_focusedMonth);
    final monthLabel = formatMonthDotLabel(_focusedMonth);

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '캘린더',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: _CalendarOverviewCard(
                  monthLabel: monthLabel,
                  weekdayLabels: calendarWeekdayLabels,
                  dates: dates,
                  focusedMonth: _focusedMonth,
                  selectedDate: _selectedDate,
                  scheduleCountForDate: _scheduleCountFor,
                  onTapPreviousMonth: _goToPreviousMonth,
                  onTapNextMonth: _goToNextMonth,
                  onTapDate: _onTapDate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ScheduleDetailSheetResult { closed, backToList, deleteRequested, deleted }

class _CalendarOverviewCard extends StatelessWidget {
  final String monthLabel;
  final List<String> weekdayLabels;
  final List<DateTime> dates;
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final int Function(DateTime date) scheduleCountForDate;
  final VoidCallback onTapPreviousMonth;
  final VoidCallback onTapNextMonth;
  final ValueChanged<DateTime> onTapDate;

  const _CalendarOverviewCard({
    required this.monthLabel,
    required this.weekdayLabels,
    required this.dates,
    required this.focusedMonth,
    required this.selectedDate,
    required this.scheduleCountForDate,
    required this.onTapPreviousMonth,
    required this.onTapNextMonth,
    required this.onTapDate,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                monthLabel,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: palette.textPrimary,
                ),
              ),
            ),
            _MiniArrowButton(
              icon: Icons.chevron_left_rounded,
              onTap: onTapPreviousMonth,
            ),
            const SizedBox(width: 6),
            _MiniArrowButton(
              icon: Icons.chevron_right_rounded,
              onTap: onTapNextMonth,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: List.generate(weekdayLabels.length, (index) {
            return _WeekdayHeader(
              label: weekdayLabels[index],
              isSunday: index == 0,
              isSaturday: index == 6,
            );
          }),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalSpacing = 5 * 12.0;
              final cellHeight = ((constraints.maxHeight - totalSpacing) / 6)
                  .clamp(56.0, 68.0);

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dates.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 4,
                  mainAxisExtent: cellHeight,
                ),
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final normalizedDate = calendarDateOnly(date);
                  final isCurrentMonth = date.month == focusedMonth.month;
                  final isSelected =
                      normalizedDate == calendarDateOnly(selectedDate);
                  final today = calendarDateOnly(DateTime.now());
                  final isToday = normalizedDate == today;
                  final scheduleCount = scheduleCountForDate(normalizedDate);

                  return _CalendarDateCell(
                    date: date,
                    isCurrentMonth: isCurrentMonth,
                    isSelected: isSelected,
                    isToday: isToday,
                    scheduleCount: scheduleCount,
                    onTap: () => onTapDate(date),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CalendarDayColors {
  final Color active;
  final Color inactive;

  const _CalendarDayColors({required this.active, required this.inactive});
}

_CalendarDayColors _dayColors(AppPalette palette, DateTime date) {
  if (date.weekday % 7 == 0) {
    return _CalendarDayColors(
      active: palette.danger.withValues(alpha: 0.88),
      inactive: palette.danger.withValues(alpha: 0.36),
    );
  }
  if (date.weekday == DateTime.saturday) {
    return _CalendarDayColors(
      active: const Color(0xFF4D84E8),
      inactive: const Color(0xFF9EBBF2),
    );
  }
  return _CalendarDayColors(
    active: palette.textPrimary,
    inactive: palette.textTertiary.withValues(alpha: 0.72),
  );
}

class _DateSchedulesBottomSheet extends StatelessWidget {
  final DateTime selectedDate;
  final List<CalendarSchedule> schedules;
  final VoidCallback onTapAdd;
  final ValueChanged<CalendarSchedule> onTapSchedule;
  final ValueChanged<CalendarSchedule> onTapEdit;

  const _DateSchedulesBottomSheet({
    required this.selectedDate,
    required this.schedules,
    required this.onTapAdd,
    required this.onTapSchedule,
    required this.onTapEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final palette = context.palette;

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.78,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.border.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SelectedDateHeader(
                selectedDate: selectedDate,
                scheduleCount: schedules.length,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: schedules.isEmpty
                      ? _ScheduleEmptyState(
                          key: ValueKey(
                            'empty_${selectedDate.toIso8601String()}',
                          ),
                          onTapAdd: onTapAdd,
                        )
                      : ListView.separated(
                          key: ValueKey(
                            'list_${selectedDate.toIso8601String()}',
                          ),
                          itemCount: schedules.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final schedule = schedules[index];
                            return _ScheduleCard(
                              schedule: schedule,
                              onTap: () => onTapSchedule(schedule),
                              onTapEdit: () => onTapEdit(schedule),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDateHeader extends StatelessWidget {
  final DateTime selectedDate;
  final int scheduleCount;

  const _SelectedDateHeader({
    required this.selectedDate,
    required this.scheduleCount,
  });

  String get _weekdayLabel {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    return labels[selectedDate.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${selectedDate.month}월 ${selectedDate.day}일 $_weekdayLabel요일',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '총 $scheduleCount개 일정',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ScheduleEmptyState extends StatelessWidget {
  final VoidCallback onTapAdd;

  const _ScheduleEmptyState({super.key, required this.onTapAdd});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: palette.primarySoft.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: palette.primaryStrong,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '오늘은 일정이 없어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '치료 전 준비나 방문 후 체크를 놓치지 않도록 일정을 추가해보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          _PrimaryActionButton(label: '일정 추가하기', onTap: onTapAdd),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final CalendarSchedule schedule;
  final VoidCallback onTap;
  final VoidCallback onTapEdit;

  const _ScheduleCard({
    required this.schedule,
    required this.onTap,
    required this.onTapEdit,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final status = _scheduleStatus(context, schedule.dateTime);

    return Material(
      color: palette.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: palette.primarySoft.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            schedule.timeText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: palette.primaryStrong,
                            ),
                          ),
                        ),
                        _StatusPill(
                          label: status.label,
                          backgroundColor: status.backgroundColor,
                          textColor: status.textColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onTapEdit,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: palette.surfaceSoft.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 17,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                schedule.hospitalName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${schedule.dateText} · ${schedule.reminderSummary}',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _ScheduleStatusData _scheduleStatus(BuildContext context, DateTime dateTime) {
    final palette = context.palette;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = targetDate.difference(todayDate).inDays;

    if (diff < 0) {
      return _ScheduleStatusData(
        label: '지난 일정',
        backgroundColor: palette.surfaceMuted,
        textColor: palette.textSecondary,
      );
    }
    if (diff == 0) {
      return _ScheduleStatusData(
        label: 'D-day',
        backgroundColor: palette.primaryStrong,
        textColor: palette.surface,
      );
    }
    return _ScheduleStatusData(
      label: 'D-$diff',
      backgroundColor: palette.primarySoft,
      textColor: palette.primaryStrong,
    );
  }
}

class _ScheduleStatusData {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _ScheduleStatusData({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.primarySoft.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: palette.primaryStrong,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarDateCell extends StatelessWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final int scheduleCount;
  final VoidCallback onTap;

  const _CalendarDateCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.scheduleCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dayColors = _dayColors(palette, date);
    final textColor = isCurrentMonth ? dayColors.active : dayColors.inactive;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? palette.primary
                          : isToday
                          ? palette.primarySoft.withValues(alpha: 0.18)
                          : Colors.transparent,
                      border: isToday && !isSelected
                          ? Border.all(
                              color: palette.primary.withValues(alpha: 0.8),
                              width: 1.6,
                            )
                          : null,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : isToday
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? palette.surface
                          : isToday
                          ? palette.primaryStrong
                          : textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const SizedBox(height: 8),
              _CalendarScheduleMarker(
                scheduleCount: scheduleCount,
                isSelected: isSelected,
                palette: palette,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarScheduleMarker extends StatelessWidget {
  final int scheduleCount;
  final bool isSelected;
  final AppPalette palette;

  const _CalendarScheduleMarker({
    required this.scheduleCount,
    required this.isSelected,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    if (scheduleCount <= 0) {
      return const SizedBox(height: 10);
    }

    final markerColor = isSelected
        ? const Color(0xFFF6C94C)
        : palette.primaryStrong;
    final markerCount = scheduleCount >= 3 ? 3 : scheduleCount;

    return SizedBox(
      height: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(markerCount, (index) {
          return Container(
            width: 5,
            height: 5,
            margin: EdgeInsets.only(right: index == markerCount - 1 ? 0 : 4),
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;
  final bool isSunday;
  final bool isSaturday;

  const _WeekdayHeader({
    required this.label,
    this.isSunday = false,
    this.isSaturday = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = isSunday
        ? palette.danger.withValues(alpha: 0.82)
        : isSaturday
        ? const Color(0xFF4D84E8)
        : palette.textSecondary;

    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _CalendarScheduleBottomSheetContent extends StatelessWidget {
  final CalendarSchedule schedule;
  final VoidCallback onTapBack;
  final VoidCallback onTapEdit;
  final VoidCallback onTapDelete;
  final ValueChanged<bool> onChangedThreeDaysBefore;
  final ValueChanged<bool> onChangedOneDayBefore;
  final ValueChanged<bool> onChangedOneHourBefore;

  const _CalendarScheduleBottomSheetContent({
    required this.schedule,
    required this.onTapBack,
    required this.onTapEdit,
    required this.onTapDelete,
    required this.onChangedThreeDaysBefore,
    required this.onChangedOneDayBefore,
    required this.onChangedOneHourBefore,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.border.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                InkWell(
                  onTap: onTapBack,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: palette.surfaceSoft.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${schedule.dateTime.month}월 ${schedule.dateTime.day}일 일정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onTapEdit,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: palette.surfaceSoft.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: BoxDecoration(
                color: palette.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: palette.border.withValues(alpha: 0.72),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '병원명',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '시간',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          schedule.hospitalName,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          schedule.timeText,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surfaceSoft.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '알림 체크',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ChecklistTile(
                          label: '방문 3일 전에 알림',
                          value: schedule.isThreeDaysBefore,
                          onChanged: onChangedThreeDaysBefore,
                        ),
                        const SizedBox(height: 10),
                        _ChecklistTile(
                          label: '방문 1일 전에 알림',
                          value: schedule.isOneDayBefore,
                          onChanged: onChangedOneDayBefore,
                        ),
                        const SizedBox(height: 10),
                        _ChecklistTile(
                          label: '방문 1시간 전에 알림',
                          value: schedule.isOneHourBefore,
                          onChanged: onChangedOneHourBefore,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: onTapDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.danger.withValues(alpha: 0.12),
                        foregroundColor: palette.danger,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '일정 삭제',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ChecklistTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value
                  ? palette.primary
                  : palette.surface.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: value ? palette.primary : palette.border,
              ),
            ),
            child: value
                ? Icon(Icons.check_rounded, size: 14, color: palette.surface)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surface.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, size: 24, color: palette.icon),
        ),
      ),
    );
  }
}

class _MiniArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 22, color: palette.textSecondary),
        ),
      ),
    );
  }
}
