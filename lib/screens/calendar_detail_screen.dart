import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../widgets/visit_schedule_bottom_sheet.dart';

class CalendarDetailScreen extends StatefulWidget {
  final VisitScheduleResult? initialScheduleResult;

  const CalendarDetailScreen({super.key, this.initialScheduleResult});

  @override
  State<CalendarDetailScreen> createState() => _CalendarDetailScreenState();
}

class _CalendarDetailScreenState extends State<CalendarDetailScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  final Map<DateTime, List<CalendarSchedule>> _scheduleMap = {};

  @override
  void initState() {
    super.initState();

    final today = _dateOnly(DateTime.now());
    _focusedMonth = DateTime(today.year, today.month, 1);
    _selectedDate = today;
    _refreshSchedules();

    final initialScheduleResult = widget.initialScheduleResult;
    if (initialScheduleResult == null) return;

    final selectedDate = CalendarScheduleStore.upsertFromResult(
      initialScheduleResult,
    );
    _refreshSchedules();
    _focusedMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    _selectedDate = selectedDate;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _refreshSchedules() {
    _scheduleMap
      ..clear()
      ..addAll(CalendarScheduleStore.snapshot());
  }

  List<CalendarSchedule> _schedulesFor(DateTime date) {
    return List<CalendarSchedule>.from(
      _scheduleMap[_dateOnly(date)] ?? const <CalendarSchedule>[],
    )..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  int _scheduleCountFor(DateTime date) {
    return _scheduleMap[_dateOnly(date)]?.length ?? 0;
  }

  List<DateTime> _buildCalendarDates(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    final leadingDays = firstDayOfMonth.weekday % 7;
    final startDate = firstDayOfMonth.subtract(Duration(days: leadingDays));

    final trailingDays = 6 - (lastDayOfMonth.weekday % 7);
    final endDate = lastDayOfMonth.add(Duration(days: trailingDays));

    final dates = <DateTime>[];
    var cursor = startDate;

    while (!cursor.isAfter(endDate)) {
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
    setState(() {
      _selectedDate = _dateOnly(date);
      _focusedMonth = DateTime(date.year, date.month, 1);
    });
  }

  Future<void> _showScheduleDetailBottomSheet(CalendarSchedule schedule) async {
    final palette = context.palette;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: palette.surfaceSoft,
      barrierColor: palette.scrim,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _CalendarScheduleBottomSheetContent(
              schedule: schedule,
              onTapEdit: () async {
                Navigator.pop(context);
                await _showScheduleEditorBottomSheet(initialSchedule: schedule);
              },
              onTapDelete: () async {
                Navigator.pop(context);
                final shouldDelete = await _showDeleteConfirmDialog();
                if (shouldDelete != true) return;

                setState(() {
                  CalendarScheduleStore.removeById(schedule.id);
                  _refreshSchedules();
                });
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
  }

  Future<bool?> _showDeleteConfirmDialog() {
    final palette = context.palette;

    return showDialog<bool>(
      context: context,
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
        ? _dateOnly(selectedDate)
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
    final targetDate = _dateOnly(result.dateTime);

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
    final monthLabel = '${_focusedMonth.year}년 ${_focusedMonth.month}월';
    final selectedSchedules = _schedulesFor(_selectedDate);

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    _CalendarOverviewCard(
                      monthLabel: monthLabel,
                      dates: dates,
                      focusedMonth: _focusedMonth,
                      selectedDate: _selectedDate,
                      scheduleCountForDate: _scheduleCountFor,
                      onTapPreviousMonth: _goToPreviousMonth,
                      onTapNextMonth: _goToNextMonth,
                      onTapDate: _onTapDate,
                    ),
                    const SizedBox(height: 16),
                    _SelectedDateScheduleSection(
                      selectedDate: _selectedDate,
                      schedules: selectedSchedules,
                      onTapAdd: () => _showScheduleEditorBottomSheet(
                        selectedDate: _selectedDate,
                      ),
                      onTapSchedule: _showScheduleDetailBottomSheet,
                      onTapEdit: (schedule) => _showScheduleEditorBottomSheet(
                        initialSchedule: schedule,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarOverviewCard extends StatelessWidget {
  final String monthLabel;
  final List<DateTime> dates;
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final int Function(DateTime date) scheduleCountForDate;
  final VoidCallback onTapPreviousMonth;
  final VoidCallback onTapNextMonth;
  final ValueChanged<DateTime> onTapDate;

  const _CalendarOverviewCard({
    required this.monthLabel,
    required this.dates,
    required this.focusedMonth,
    required this.selectedDate,
    required this.scheduleCountForDate,
    required this.onTapPreviousMonth,
    required this.onTapNextMonth,
    required this.onTapDate,
  });

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthLabel,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              _MiniArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: onTapPreviousMonth,
              ),
              const SizedBox(width: 8),
              _MiniArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: onTapNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '날짜를 선택하면 아래에서 하루 일정 전체를 확인할 수 있어요.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.textSecondary,
                ),
              ),
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
                  '일정 ${scheduleCountForDate(selectedDate)}개',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: palette.primaryStrong,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              _WeekdayHeader(label: '일', isSunday: true),
              _WeekdayHeader(label: '월'),
              _WeekdayHeader(label: '화'),
              _WeekdayHeader(label: '수'),
              _WeekdayHeader(label: '목'),
              _WeekdayHeader(label: '금'),
              _WeekdayHeader(label: '토'),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dates.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 78,
            ),
            itemBuilder: (context, index) {
              final date = dates[index];
              final normalizedDate = _dateOnly(date);
              final isCurrentMonth = date.month == focusedMonth.month;
              final isSelected = normalizedDate == _dateOnly(selectedDate);
              final scheduleCount = scheduleCountForDate(normalizedDate);

              return _CalendarDateCell(
                date: date,
                isCurrentMonth: isCurrentMonth,
                isSelected: isSelected,
                scheduleCount: scheduleCount,
                onTap: () => onTapDate(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SelectedDateScheduleSection extends StatelessWidget {
  final DateTime selectedDate;
  final List<CalendarSchedule> schedules;
  final VoidCallback onTapAdd;
  final ValueChanged<CalendarSchedule> onTapSchedule;
  final ValueChanged<CalendarSchedule> onTapEdit;

  const _SelectedDateScheduleSection({
    required this.selectedDate,
    required this.schedules,
    required this.onTapAdd,
    required this.onTapSchedule,
    required this.onTapEdit,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectedDateHeader(
            selectedDate: selectedDate,
            scheduleCount: schedules.length,
            onTapAdd: onTapAdd,
          ),
          const SizedBox(height: 16),
          if (schedules.isEmpty)
            _ScheduleEmptyState(selectedDate: selectedDate, onTapAdd: onTapAdd)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: schedules.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                return _ScheduleCard(
                  schedule: schedule,
                  onTap: () => onTapSchedule(schedule),
                  onTapEdit: () => onTapEdit(schedule),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SelectedDateHeader extends StatelessWidget {
  final DateTime selectedDate;
  final int scheduleCount;
  final VoidCallback onTapAdd;

  const _SelectedDateHeader({
    required this.selectedDate,
    required this.scheduleCount,
    required this.onTapAdd,
  });

  String get _weekdayLabel {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    return labels[selectedDate.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final textBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${selectedDate.month}월 ${selectedDate.day}일 $_weekdayLabel요일',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              scheduleCount == 0
                  ? '아직 등록된 일정이 없어요.'
                  : '총 $scheduleCount개의 케어 일정이 준비되어 있어요.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ],
        );

        return Flex(
          direction: compact ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: compact
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            if (compact) textBlock else Expanded(child: textBlock),
            SizedBox(width: compact ? 0 : 12, height: compact ? 12 : 0),
            _PrimaryActionButton(label: '일정 추가하기', onTap: onTapAdd),
          ],
        );
      },
    );
  }
}

class _ScheduleEmptyState extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTapAdd;

  const _ScheduleEmptyState({
    required this.selectedDate,
    required this.onTapAdd,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: palette.primaryStrong,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${selectedDate.month}월 ${selectedDate.day}일에는 아직 일정이 없어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '치료 전 준비나 방문 후 체크를 놓치지 않도록 일정을 추가해보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w700,
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
      color: palette.surfaceSoft,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border),
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
                            color: palette.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            schedule.timeText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.border),
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
              const SizedBox(height: 14),
              Text(
                schedule.hospitalName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${schedule.dateText} · ${schedule.reminderSummary}',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
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
          fontWeight: FontWeight.w900,
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
      color: palette.primarySoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
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
  final int scheduleCount;
  final VoidCallback onTap;

  const _CalendarDateCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.scheduleCount,
    required this.onTap,
  });

  bool get _isSunday => date.weekday % 7 == 0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final textColor = !isCurrentMonth
        ? palette.textTertiary
        : _isSunday
        ? palette.danger
        : palette.textPrimary;

    return Material(
      color: isSelected ? palette.primarySoft : palette.surfaceSoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? palette.primaryStrong : palette.border,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? palette.primary
                      : palette.surface.withValues(alpha: 0),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? palette.surface : textColor,
                  ),
                ),
              ),
              const Spacer(),
              if (scheduleCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? palette.primaryStrong : palette.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    scheduleCount > 9 ? '9+' : '$scheduleCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: palette.surface,
                    ),
                  ),
                )
              else
                const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;
  final bool isSunday;

  const _WeekdayHeader({required this.label, this.isSunday = false});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isSunday ? palette.danger : palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CalendarScheduleBottomSheetContent extends StatelessWidget {
  final CalendarSchedule schedule;
  final VoidCallback onTapEdit;
  final VoidCallback onTapDelete;
  final ValueChanged<bool> onChangedThreeDaysBefore;
  final ValueChanged<bool> onChangedOneDayBefore;
  final ValueChanged<bool> onChangedOneHourBefore;

  const _CalendarScheduleBottomSheetContent({
    required this.schedule,
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
                width: 64,
                height: 8,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${schedule.dateTime.month}월 ${schedule.dateTime.day}일 일정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onTapEdit,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: palette.border),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '병원명',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '시간',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
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
                            fontWeight: FontWeight.w900,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          schedule.timeText,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
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
                      color: palette.surfaceSoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: palette.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '알림 체크',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ChecklistTile(
                          label: '3일 전 알림',
                          value: schedule.isThreeDaysBefore,
                          onChanged: onChangedThreeDaysBefore,
                        ),
                        const SizedBox(height: 10),
                        _ChecklistTile(
                          label: '1일 전 알림',
                          value: schedule.isOneDayBefore,
                          onChanged: onChangedOneDayBefore,
                        ),
                        const SizedBox(height: 10),
                        _ChecklistTile(
                          label: '1시간 전 알림',
                          value: schedule.isOneHourBefore,
                          onChanged: onChangedOneHourBefore,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onTapDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.danger.withValues(alpha: 0.14),
                        foregroundColor: palette.danger,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '일정 삭제',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
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
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value
                  ? palette.primary
                  : palette.surface.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value ? palette.primary : palette.border,
              ),
            ),
            child: value
                ? Icon(Icons.check_rounded, size: 16, color: palette.surface)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
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
      color: palette.surface,
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
      color: palette.surfaceSoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 24, color: palette.textSecondary),
        ),
      ),
    );
  }
}

class CalendarSchedule {
  final String id;
  String hospitalName;
  DateTime dateTime;
  bool isThreeDaysBefore;
  bool isOneDayBefore;
  bool isOneHourBefore;

  CalendarSchedule({
    required this.id,
    required this.hospitalName,
    required this.dateTime,
    this.isThreeDaysBefore = false,
    this.isOneDayBefore = false,
    this.isOneHourBefore = false,
  });

  CalendarSchedule copyWith({
    String? id,
    String? hospitalName,
    DateTime? dateTime,
    bool? isThreeDaysBefore,
    bool? isOneDayBefore,
    bool? isOneHourBefore,
  }) {
    return CalendarSchedule(
      id: id ?? this.id,
      hospitalName: hospitalName ?? this.hospitalName,
      dateTime: dateTime ?? this.dateTime,
      isThreeDaysBefore: isThreeDaysBefore ?? this.isThreeDaysBefore,
      isOneDayBefore: isOneDayBefore ?? this.isOneDayBefore,
      isOneHourBefore: isOneHourBefore ?? this.isOneHourBefore,
    );
  }

  String get timeText {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    return '$period $displayHour:${minute.toString().padLeft(2, '0')}';
  }

  String get dateText {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    final weekdayLabel = labels[dateTime.weekday % 7];
    return '${dateTime.month}월 ${dateTime.day}일 $weekdayLabel요일';
  }

  String get reminderSummary {
    final items = <String>[];
    if (isThreeDaysBefore) items.add('3일 전');
    if (isOneDayBefore) items.add('1일 전');
    if (isOneHourBefore) items.add('1시간 전');

    if (items.isEmpty) {
      return '알림 없음';
    }

    return '알림 ${items.join(', ')}';
  }
}

class CalendarScheduleStore {
  static int _idSeed = 0;

  static final Map<DateTime, List<CalendarSchedule>> _scheduleMap = {
    _dateOnly(DateTime(2026, 6, 11)): [
      CalendarSchedule(
        id: createId(),
        hospitalName: '샤프 의원',
        dateTime: DateTime(2026, 6, 11, 10, 30),
        isThreeDaysBefore: true,
      ),
      CalendarSchedule(
        id: createId(),
        hospitalName: '리프 클리닉',
        dateTime: DateTime(2026, 6, 11, 19),
        isOneDayBefore: true,
      ),
    ],
    _dateOnly(DateTime(2026, 6, 13)): [
      CalendarSchedule(
        id: createId(),
        hospitalName: 'YY 의원',
        dateTime: DateTime(2026, 6, 13, 14, 30),
        isThreeDaysBefore: true,
        isOneDayBefore: true,
      ),
      CalendarSchedule(
        id: createId(),
        hospitalName: '아크 피부과',
        dateTime: DateTime(2026, 6, 13, 17),
        isOneHourBefore: true,
      ),
    ],
    _dateOnly(DateTime(2026, 6, 28)): [
      CalendarSchedule(
        id: createId(),
        hospitalName: '범석 재호',
        dateTime: DateTime(2026, 6, 28, 9),
        isOneDayBefore: true,
        isOneHourBefore: true,
      ),
    ],
  };

  static String createId() {
    _idSeed += 1;
    return 'schedule_${DateTime.now().microsecondsSinceEpoch}_$_idSeed';
  }

  static Map<DateTime, List<CalendarSchedule>> snapshot() {
    return {
      for (final entry in _scheduleMap.entries)
        entry.key: entry.value.map((schedule) => schedule.copyWith()).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime)),
    };
  }

  static DateTime upsertFromResult(VisitScheduleResult result) {
    final schedule = CalendarSchedule(
      id: createId(),
      hospitalName: result.hospitalName.isEmpty
          ? '병원명을 입력해주세요'
          : result.hospitalName,
      dateTime: result.dateTime,
    );
    upsert(schedule);
    return _dateOnly(result.dateTime);
  }

  static void upsert(CalendarSchedule schedule) {
    removeById(schedule.id);

    final targetDate = _dateOnly(schedule.dateTime);
    final schedules = _scheduleMap.putIfAbsent(
      targetDate,
      () => <CalendarSchedule>[],
    );
    schedules.add(schedule.copyWith());
    schedules.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  static void removeById(String scheduleId) {
    final emptyDates = <DateTime>[];

    for (final entry in _scheduleMap.entries) {
      entry.value.removeWhere((schedule) => schedule.id == scheduleId);
      if (entry.value.isEmpty) {
        emptyDates.add(entry.key);
      }
    }

    for (final date in emptyDates) {
      _scheduleMap.remove(date);
    }
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
