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
  DateTime _focusedMonth = DateTime(2026, 6, 1);
  DateTime? _selectedDate;

  late final Map<DateTime, CalendarSchedule> _scheduleMap;

  @override
  void initState() {
    super.initState();
    _scheduleMap = CalendarScheduleStore.snapshot();

    final initialScheduleResult = widget.initialScheduleResult;
    if (initialScheduleResult == null) return;

    final selectedDate = CalendarScheduleStore.upsertFromResult(
      initialScheduleResult,
    );
    _scheduleMap
      ..clear()
      ..addAll(CalendarScheduleStore.snapshot());
    _focusedMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    _selectedDate = selectedDate;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<DateTime> _buildCalendarDates(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    final int leadingDays = firstDayOfMonth.weekday % 7;
    final DateTime startDate = firstDayOfMonth.subtract(
      Duration(days: leadingDays),
    );

    final int trailingDays = 6 - (lastDayOfMonth.weekday % 7);
    final DateTime endDate = lastDayOfMonth.add(Duration(days: trailingDays));

    final dates = <DateTime>[];
    DateTime cursor = startDate;

    while (!cursor.isAfter(endDate)) {
      dates.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    return dates;
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      _selectedDate = null;
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
      _selectedDate = null;
    });
  }

  void _onTapDate(DateTime date) {
    final selected = _dateOnly(date);

    setState(() {
      _selectedDate = selected;
    });

    final existing = _scheduleMap[selected];
    if (existing == null) {
      _showScheduleEditorBottomSheet(selectedDate: selected);
    } else {
      _showScheduleDetailBottomSheet(selected, existing);
    }
  }

  Future<void> _showScheduleDetailBottomSheet(
    DateTime selectedDate,
    CalendarSchedule schedule,
  ) async {
    final palette = context.palette;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface.withValues(alpha: 0),
      barrierColor: palette.scrim,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _CalendarScheduleBottomSheet(
              selectedDate: selectedDate,
              schedule: schedule,
              onTapEdit: () async {
                Navigator.pop(context);
                await _showScheduleEditorBottomSheet(
                  selectedDate: selectedDate,
                  initialSchedule: schedule,
                );
              },
              onTapDelete: () async {
                Navigator.pop(context);
                final shouldDelete = await _showDeleteConfirmDialog();
                if (shouldDelete == true) {
                  setState(() {
                    CalendarScheduleStore.remove(selectedDate);
                    _scheduleMap.remove(selectedDate);
                    if (_selectedDate == selectedDate) {
                      _selectedDate = null;
                    }
                  });
                }
              },
              onChangedThreeDaysBefore: (value) {
                setState(() {
                  schedule.isThreeDaysBefore = value;
                });
                setModalState(() {});
              },
              onChangedOneDayBefore: (value) {
                setState(() {
                  schedule.isOneDayBefore = value;
                });
                setModalState(() {});
              },
              onChangedOneHourBefore: (value) {
                setState(() {
                  schedule.isOneHourBefore = value;
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
    required DateTime selectedDate,
    CalendarSchedule? initialSchedule,
  }) async {
    final initialDateTime = initialSchedule?.dateTime ?? selectedDate;
    final result = await showVisitScheduleBottomSheet(
      context,
      initialDateTime: initialDateTime,
      initialHospitalName: initialSchedule?.hospitalName,
      title: initialSchedule == null ? '일정을 등록할까요?' : '일정을 수정할까요?',
    );

    if (result == null) return;

    final targetDate = _dateOnly(result.dateTime);

    setState(() {
      final schedule = CalendarSchedule(
        hospitalName: result.hospitalName.isEmpty
            ? '병원명을 입력해주세요'
            : result.hospitalName,
        dateTime: result.dateTime,
        isThreeDaysBefore: initialSchedule?.isThreeDaysBefore ?? false,
        isOneDayBefore: initialSchedule?.isOneDayBefore ?? false,
        isOneHourBefore: initialSchedule?.isOneHourBefore ?? false,
      );

      if (targetDate != selectedDate) {
        CalendarScheduleStore.remove(selectedDate);
        _scheduleMap.remove(selectedDate);
      }

      CalendarScheduleStore.upsert(schedule);
      _scheduleMap[targetDate] = schedule;
      _focusedMonth = DateTime(targetDate.year, targetDate.month, 1);
      _selectedDate = targetDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dates = _buildCalendarDates(_focusedMonth);
    final monthLabel = '${_focusedMonth.year}년 ${_focusedMonth.month}월';

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
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
                          onTap: _goToPreviousMonth,
                        ),
                        const SizedBox(width: 8),
                        _MiniArrowButton(
                          icon: Icons.chevron_right_rounded,
                          onTap: _goToNextMonth,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
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
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dates.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              mainAxisExtent: 88,
                            ),
                        itemBuilder: (context, index) {
                          final date = dates[index];
                          final normalizedDate = _dateOnly(date);
                          final isCurrentMonth =
                              date.month == _focusedMonth.month;
                          final isSelected =
                              _selectedDate != null &&
                              _dateOnly(_selectedDate!) == normalizedDate;
                          final hasSchedule = _scheduleMap.containsKey(
                            normalizedDate,
                          );

                          return _CalendarDateCell(
                            date: date,
                            isCurrentMonth: isCurrentMonth,
                            isSelected: isSelected,
                            hasSchedule: hasSchedule,
                            onTap: () => _onTapDate(date),
                          );
                        },
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

class _CalendarDateCell extends StatelessWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool hasSchedule;
  final VoidCallback onTap;

  const _CalendarDateCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.hasSchedule,
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
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? palette.primaryStrong : palette.border,
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
              if (hasSchedule)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: palette.primary,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 14),
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

class _CalendarScheduleBottomSheet extends StatelessWidget {
  final DateTime selectedDate;
  final CalendarSchedule schedule;
  final VoidCallback onTapEdit;
  final VoidCallback onTapDelete;
  final ValueChanged<bool> onChangedThreeDaysBefore;
  final ValueChanged<bool> onChangedOneDayBefore;
  final ValueChanged<bool> onChangedOneHourBefore;

  const _CalendarScheduleBottomSheet({
    required this.selectedDate,
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        decoration: BoxDecoration(
          color: palette.surfaceSoft,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
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
                    '${selectedDate.month}월 ${selectedDate.day}일 일정',
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
  String hospitalName;
  DateTime dateTime;
  bool isThreeDaysBefore;
  bool isOneDayBefore;
  bool isOneHourBefore;

  CalendarSchedule({
    required this.hospitalName,
    required this.dateTime,
    this.isThreeDaysBefore = false,
    this.isOneDayBefore = false,
    this.isOneHourBefore = false,
  });

  int get hour => dateTime.hour;

  int get minute => dateTime.minute;

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
}

class CalendarScheduleStore {
  static final Map<DateTime, CalendarSchedule> _scheduleMap = {
    _dateOnly(DateTime(2026, 6, 11)): CalendarSchedule(
      hospitalName: '샤프 의원',
      dateTime: DateTime(2026, 6, 11, 19),
      isThreeDaysBefore: true,
      isOneDayBefore: false,
      isOneHourBefore: false,
    ),
    _dateOnly(DateTime(2026, 6, 13)): CalendarSchedule(
      hospitalName: 'YY 의원',
      dateTime: DateTime(2026, 6, 13, 14, 30),
      isThreeDaysBefore: true,
      isOneDayBefore: true,
      isOneHourBefore: false,
    ),
    _dateOnly(DateTime(2026, 6, 28)): CalendarSchedule(
      hospitalName: '범석 재호',
      dateTime: DateTime(2026, 6, 28, 9),
      isThreeDaysBefore: false,
      isOneDayBefore: true,
      isOneHourBefore: true,
    ),
  };

  static Map<DateTime, CalendarSchedule> snapshot() {
    return Map<DateTime, CalendarSchedule>.from(_scheduleMap);
  }

  static DateTime upsertFromResult(VisitScheduleResult result) {
    final schedule = CalendarSchedule(
      hospitalName: result.hospitalName.isEmpty
          ? '병원명을 입력해주세요'
          : result.hospitalName,
      dateTime: result.dateTime,
    );
    upsert(schedule);
    return _dateOnly(result.dateTime);
  }

  static void upsert(CalendarSchedule schedule) {
    _scheduleMap[_dateOnly(schedule.dateTime)] = schedule;
  }

  static void remove(DateTime date) {
    _scheduleMap.remove(_dateOnly(date));
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
