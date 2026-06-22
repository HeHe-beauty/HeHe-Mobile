import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hehe/common/utils/app_time.dart';

import '../theme/app_palette.dart';

class VisitScheduleResult {
  final String hospitalName;
  final DateTime visitDateTime;

  const VisitScheduleResult({
    required this.hospitalName,
    required this.visitDateTime,
  });
}

Future<VisitScheduleResult?> showVisitScheduleBottomSheet(
  BuildContext context, {
  DateTime? initialDateTime,
  DateTime? fixedDate,
  String? initialHospitalName,
  String? title,
  String confirmLabel = '완료',
  ValueChanged<VisitScheduleResult>? onConfirm,
}) {
  final palette = context.palette;

  return showModalBottomSheet<VisitScheduleResult>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    isScrollControlled: true,
    backgroundColor: palette.bottomSheetSurface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    barrierColor: palette.modalBarrier,
    builder: (_) {
      return VisitScheduleBottomSheet(
        initialDateTime: initialDateTime,
        fixedDate: fixedDate,
        initialHospitalName: initialHospitalName,
        title: title,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
      );
    },
  );
}

class VisitScheduleBottomSheet extends StatefulWidget {
  final DateTime? initialDateTime;
  final DateTime? fixedDate;
  final String? initialHospitalName;
  final String? title;
  final String confirmLabel;
  final ValueChanged<VisitScheduleResult>? onConfirm;

  const VisitScheduleBottomSheet({
    super.key,
    this.initialDateTime,
    this.fixedDate,
    this.initialHospitalName,
    this.title,
    this.confirmLabel = '완료',
    this.onConfirm,
  });

  @override
  State<VisitScheduleBottomSheet> createState() =>
      _VisitScheduleBottomSheetState();
}

class _VisitScheduleBottomSheetState extends State<VisitScheduleBottomSheet> {
  late final TextEditingController _hospitalController;
  late final FocusNode _hospitalFocusNode;

  bool _showHospitalNameError = false;
  late bool _hasSelectedDate;
  late bool _hasSelectedTime;

  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  late int _selectedHour;
  late int _selectedMinute;

  bool get _isFixedDateMode => widget.fixedDate != null;

  DateTime get _effectiveFixedDate => widget.fixedDate!;

  bool get _canSubmit =>
      _hospitalController.text.trim().isNotEmpty &&
      _hasSelectedDate &&
      _hasSelectedTime;

  String get _selectedDateLabel {
    if (!_hasSelectedDate) return '';
    if (_isFixedDateMode) return _fixedDateLabel;

    final date = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String get _selectedTimeLabel {
    if (!_hasSelectedTime) return '';
    return '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';
  }

  String get _fixedDateLabel {
    final date = _effectiveFixedDate;
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  @override
  void initState() {
    super.initState();

    final now = AppTime.now();
    final initialDateTime = widget.initialDateTime ?? now;
    final minYear = now.year;

    _selectedYear = math.max(initialDateTime.year, minYear);
    _selectedMonth = initialDateTime.month;
    _selectedDay = initialDateTime.day;
    _selectedHour = initialDateTime.hour;
    _selectedMinute = initialDateTime.minute;
    final hasInitialSchedule = (widget.initialHospitalName ?? '')
        .trim()
        .isNotEmpty;
    _hasSelectedDate = _isFixedDateMode || hasInitialSchedule;
    _hasSelectedTime = hasInitialSchedule;

    _hospitalController = TextEditingController(
      text: widget.initialHospitalName ?? '',
    );
    _hospitalFocusNode = FocusNode();
    _hospitalController.addListener(_onHospitalNameChanged);
  }

  @override
  void dispose() {
    _hospitalController.removeListener(_onHospitalNameChanged);
    _hospitalController.dispose();
    _hospitalFocusNode.dispose();
    super.dispose();
  }

  void _onHospitalNameChanged() {
    if (!mounted) return;

    if (_showHospitalNameError && _hospitalController.text.trim().isNotEmpty) {
      setState(() {
        _showHospitalNameError = false;
      });
      return;
    }

    setState(() {});
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();

    final hospitalName = _hospitalController.text.trim();
    if (hospitalName.isEmpty) {
      setState(() {
        _showHospitalNameError = true;
      });
      _hospitalFocusNode.requestFocus();
      return;
    }

    final result = VisitScheduleResult(
      hospitalName: hospitalName,
      visitDateTime: DateTime(
        _isFixedDateMode ? _effectiveFixedDate.year : _selectedYear,
        _isFixedDateMode ? _effectiveFixedDate.month : _selectedMonth,
        _isFixedDateMode ? _effectiveFixedDate.day : _selectedDay,
        _selectedHour,
        _selectedMinute,
      ),
    );

    widget.onConfirm?.call(result);
    Navigator.of(context).pop(result);
  }

  void _syncDaySelection() {
    final maxDay = _daysInMonth(_selectedYear, _selectedMonth);
    if (_selectedDay <= maxDay) return;

    _selectedDay = maxDay;
  }

  void _moveCalendarMonth(int offset) {
    final nextMonth = DateTime(_selectedYear, _selectedMonth + offset);

    HapticFeedback.selectionClick();
    setState(() {
      _selectedYear = nextMonth.year;
      _selectedMonth = nextMonth.month;
      _syncDaySelection();
    });
  }

  void _selectCalendarDay(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedYear = date.year;
      _selectedMonth = date.month;
      _selectedDay = date.day;
      _hasSelectedDate = true;
    });
  }

  void _selectTimeOption(_TimeOption option) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedHour = option.hour;
      _selectedMinute = option.minute;
      _hasSelectedTime = true;
    });
  }

  Future<void> _openDatePicker() async {
    if (_isFixedDateMode) return;

    FocusManager.instance.primaryFocus?.unfocus();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: context.palette.modalBarrier,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            return _PickerSheetFrame(
              title: '날짜 선택',
              onClose: () => Navigator.of(context).pop(),
              child: _CalendarDatePickerBody(
                year: _selectedYear,
                month: _selectedMonth,
                selectedDay: _hasSelectedDate ? _selectedDay : null,
                onPreviousMonth: () {
                  _moveCalendarMonth(-1);
                  setPickerState(() {});
                },
                onNextMonth: () {
                  _moveCalendarMonth(1);
                  setPickerState(() {});
                },
                onSelectDay: (date) {
                  _selectCalendarDay(date);
                  setPickerState(() {});
                },
                onConfirm: _hasSelectedDate
                    ? () => Navigator.of(context).pop()
                    : null,
                confirmLabel: _hasSelectedDate
                    ? '$_selectedDateLabel 선택'
                    : '날짜를 선택해주세요',
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openTimePicker() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final initialMinute = _nearestQuarterMinute(_selectedMinute);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: context.palette.modalBarrier,
      builder: (modalContext) {
        return _PickerSheetFrame(
          title: '시간 선택',
          onClose: () => Navigator.of(modalContext).pop(),
          child: _TimeWheelPickerBody(
            selectedHour: _selectedHour,
            selectedMinute: initialMinute,
            onConfirm: (option) {
              _selectTimeOption(option);
              Navigator.of(modalContext).pop();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomPadding = mediaQuery.padding.bottom;
    final contentBottomPadding = math.max(bottomPadding, 8.0);

    return SafeArea(
      top: false,
      bottom: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, contentBottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.bottomSheetBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 28,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 42),
                          child: Text(
                            widget.title ?? '병원 방문 일정을 등록할까요?',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -8,
                        top: 0,
                        bottom: 0,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close_rounded),
                          color: palette.textSecondary,
                          iconSize: 22,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _HospitalInputRow(
                  controller: _hospitalController,
                  focusNode: _hospitalFocusNode,
                  hasError: _showHospitalNameError,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                _ScheduleInputRow(
                  icon: Icons.calendar_month_rounded,
                  label: '언제 방문하세요?',
                  value: _selectedDateLabel,
                  placeholder: '날짜 선택',
                  onTap: _isFixedDateMode ? null : _openDatePicker,
                ),
                const SizedBox(height: 12),
                _ScheduleInputRow(
                  icon: Icons.access_time_rounded,
                  label: '몇시에 방문하세요?',
                  value: _selectedTimeLabel,
                  placeholder: '시간 선택',
                  onTap: _openTimePicker,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Material(
                    color: _canSubmit ? palette.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(_canSubmit ? 12 : 16),
                    child: InkWell(
                      onTap: _canSubmit ? _submit : null,
                      borderRadius: BorderRadius.circular(_canSubmit ? 12 : 16),
                      child: Ink(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: _canSubmit
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF8C97FF),
                                    Color(0xFF7482FF),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          borderRadius: BorderRadius.circular(
                            _canSubmit ? 12 : 16,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '등록하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static int _nearestQuarterMinute(int minute) {
    return _allowedMinutes.reduce((nearest, candidate) {
      final nearestDistance = (minute - nearest).abs();
      final candidateDistance = (minute - candidate).abs();
      return candidateDistance < nearestDistance ? candidate : nearest;
    });
  }
}

const List<int> _allowedMinutes = [0, 15, 30, 45];

class _PickerSheetFrame extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final Widget child;

  const _PickerSheetFrame({
    required this.title,
    required this.onClose,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.bottomSheetSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: palette.bottomSheetBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -8,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                      color: palette.textSecondary,
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _TimeOption {
  final int hour;
  final int minute;

  const _TimeOption({required this.hour, required this.minute});
}

class _HospitalInputRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onSubmitted;

  const _HospitalInputRow({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? palette.bottomSheetBorder
        : const Color(0xFFE5E7EF);
    final placeholderColor = Theme.of(context).brightness == Brightness.dark
        ? palette.textTertiary
        : const Color(0xFFA8AFBD);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasError) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 5, left: 52),
            child: _RequiredInputBubble(color: palette.danger),
          ),
        ],
        Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: palette.bottomSheetInnerSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError ? palette.danger : borderColor,
              width: hasError ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.person_pin_rounded, size: 23, color: placeholderColor),
              const SizedBox(width: 12),
              Text(
                '병원명',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textAlign: TextAlign.right,
                  textInputAction: TextInputAction.done,
                  onSubmitted: onSubmitted,
                  decoration: InputDecoration(
                    hintText: '병원명을 입력해주세요',
                    hintStyle: TextStyle(
                      color: placeholderColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduleInputRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String placeholder;
  final VoidCallback? onTap;

  const _ScheduleInputRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasValue = value.trim().isNotEmpty;
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? palette.bottomSheetBorder
        : const Color(0xFFE5E7EF);
    final placeholderColor = Theme.of(context).brightness == Brightness.dark
        ? palette.textTertiary
        : const Color(0xFFA8AFBD);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: palette.bottomSheetInnerSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 23, color: placeholderColor),
              const SizedBox(width: 12),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    hasValue ? value : placeholder,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: hasValue ? palette.textPrimary : placeholderColor,
                    ),
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

class _RequiredInputBubble extends StatelessWidget {
  final Color color;

  const _RequiredInputBubble({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(9, 5, 9, 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '필수 입력',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: CustomPaint(
            size: const Size(10, 7),
            painter: _RequiredInputBubbleTailPainter(color: color),
          ),
        ),
      ],
    );
  }
}

class _RequiredInputBubbleTailPainter extends CustomPainter {
  final Color color;

  const _RequiredInputBubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RequiredInputBubbleTailPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _CalendarDatePickerBody extends StatelessWidget {
  final int year;
  final int month;
  final int? selectedDay;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback? onConfirm;
  final String confirmLabel;

  const _CalendarDatePickerBody({
    required this.year,
    required this.month,
    required this.selectedDay,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDay,
    required this.onConfirm,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final days = _calendarCells(year, month);
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPreviousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
              color: palette.textSecondary,
              splashRadius: 20,
            ),
            Expanded(
              child: Text(
                '$year. $month',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: palette.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: onNextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
              color: palette.textSecondary,
              splashRadius: 20,
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: weekdays.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 30,
          ),
          itemBuilder: (context, index) {
            final isSunday = index == 0;
            final isSaturday = index == 6;
            return Center(
              child: Text(
                weekdays[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSunday
                      ? palette.danger
                      : isSaturday
                      ? palette.primary
                      : palette.textTertiary,
                ),
              ),
            );
          },
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 45,
          ),
          itemBuilder: (context, index) {
            final date = days[index];
            final isCurrentMonth = date.month == month;
            final now = AppTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final cellDate = DateTime(date.year, date.month, date.day);
            final isPastDate = cellDate.isBefore(today);
            final isSelectable = isCurrentMonth && !isPastDate;
            final isSelected =
                selectedDay != null &&
                isCurrentMonth &&
                date.year == year &&
                date.day == selectedDay;
            final isToday =
                isCurrentMonth &&
                date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            final isSunday = index % 7 == 0;
            final isSaturday = index % 7 == 6;

            return Center(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: isSelectable ? () => onSelectDay(date) : null,
                  borderRadius: BorderRadius.circular(999),
                  child: Ink(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected ? palette.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: !isSelected && isToday
                          ? Border.all(
                              color: const Color(0xFFFF9F2D),
                              width: 1.6,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : !isCurrentMonth || isPastDate
                              ? palette.textTertiary.withValues(alpha: 0.52)
                              : isSunday
                              ? palette.danger
                              : isSaturday
                              ? palette.primary
                              : palette.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _PickerConfirmButton(label: confirmLabel, onTap: onConfirm),
      ],
    );
  }

  static List<DateTime> _calendarCells(int year, int month) {
    final firstDay = DateTime(year, month);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingDays = firstDay.weekday % 7;
    final cellCount = (((leadingDays + daysInMonth) / 7).ceil()) * 7;
    final firstCell = firstDay.subtract(Duration(days: leadingDays));

    return List.generate(cellCount, (index) {
      return firstCell.add(Duration(days: index));
    });
  }
}

class _TimeWheelPickerBody extends StatefulWidget {
  final int selectedHour;
  final int selectedMinute;
  final ValueChanged<_TimeOption> onConfirm;

  const _TimeWheelPickerBody({
    required this.selectedHour,
    required this.selectedMinute,
    required this.onConfirm,
  });

  @override
  State<_TimeWheelPickerBody> createState() => _TimeWheelPickerBodyState();
}

class _TimeWheelPickerBodyState extends State<_TimeWheelPickerBody> {
  static const List<String> _periods = ['오전', '오후'];
  static const List<int> _hours = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  late int _periodIndex;
  late int _hourIndex;
  late int _minuteIndex;
  late final FixedExtentScrollController _periodController;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _periodIndex = widget.selectedHour < 12 ? 0 : 1;
    final displayHour = widget.selectedHour % 12 == 0
        ? 12
        : widget.selectedHour % 12;
    _hourIndex = _hours.indexOf(displayHour);
    _minuteIndex = _allowedMinutes.indexOf(widget.selectedMinute);

    _periodController = FixedExtentScrollController(initialItem: _periodIndex);
    _hourController = FixedExtentScrollController(initialItem: _hourIndex);
    _minuteController = FixedExtentScrollController(initialItem: _minuteIndex);
  }

  @override
  void dispose() {
    _periodController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  _TimeOption get _selectedOption {
    final displayHour = _hours[_hourIndex];
    final hour = _periodIndex == 0
        ? (displayHour == 12 ? 0 : displayHour)
        : (displayHour == 12 ? 12 : displayHour + 12);

    return _TimeOption(hour: hour, minute: _allowedMinutes[_minuteIndex]);
  }

  void _changePeriod(int index) {
    HapticFeedback.selectionClick();
    setState(() => _periodIndex = index);
  }

  void _changeHour(int index) {
    HapticFeedback.selectionClick();
    setState(() => _hourIndex = index);
  }

  void _changeMinute(int index) {
    HapticFeedback.selectionClick();
    setState(() => _minuteIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 232,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          decoration: BoxDecoration(
            color: palette.bottomSheetInnerSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.bottomSheetBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _WheelHeader(label: '오전/오후', flex: 5),
                  _WheelHeader(label: '시', flex: 4),
                  _WheelHeader(label: '분', flex: 4),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: palette.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: palette.primary.withValues(alpha: 0.16),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _TimeWheel(
                            controller: _periodController,
                            labels: _periods,
                            selectedIndex: _periodIndex,
                            semanticLabel: '오전 오후',
                            onSelectedItemChanged: _changePeriod,
                          ),
                        ),
                        _WheelDivider(color: palette.bottomSheetBorder),
                        Expanded(
                          flex: 4,
                          child: _TimeWheel(
                            controller: _hourController,
                            labels: _hours.map((hour) => '$hour').toList(),
                            selectedIndex: _hourIndex,
                            semanticLabel: '시',
                            onSelectedItemChanged: _changeHour,
                          ),
                        ),
                        _WheelDivider(color: palette.bottomSheetBorder),
                        Expanded(
                          flex: 4,
                          child: _TimeWheel(
                            controller: _minuteController,
                            labels: _allowedMinutes
                                .map(
                                  (minute) => minute.toString().padLeft(2, '0'),
                                )
                                .toList(),
                            selectedIndex: _minuteIndex,
                            semanticLabel: '분',
                            onSelectedItemChanged: _changeMinute,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PickerConfirmButton(
          label: _timeOptionDisplayLabel(_selectedOption),
          onTap: () => widget.onConfirm(_selectedOption),
        ),
      ],
    );
  }

  static String _timeOptionDisplayLabel(_TimeOption option) {
    final period = option.hour < 12 ? '오전' : '오후';
    final displayHour = option.hour % 12 == 0 ? 12 : option.hour % 12;
    return '$period $displayHour:${option.minute.toString().padLeft(2, '0')} 선택';
  }
}

class _WheelHeader extends StatelessWidget {
  final String label;
  final int flex;

  const _WheelHeader({required this.label, required this.flex});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: palette.textTertiary,
        ),
      ),
    );
  }
}

class _TimeWheel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final List<String> labels;
  final int selectedIndex;
  final String semanticLabel;
  final ValueChanged<int> onSelectedItemChanged;

  const _TimeWheel({
    required this.controller,
    required this.labels,
    required this.selectedIndex,
    required this.semanticLabel,
    required this.onSelectedItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      label: semanticLabel,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 44,
        diameterRatio: 1.6,
        perspective: 0.003,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelectedItemChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: labels.length,
          builder: (context, index) {
            final isSelected = index == selectedIndex;
            return Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 120),
                style: TextStyle(
                  fontSize: isSelected ? 18 : 15,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? palette.primary : palette.textTertiary,
                ),
                child: Text(labels[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WheelDivider extends StatelessWidget {
  final Color color;

  const _WheelDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 1,
        height: 104,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: color.withValues(alpha: 0.72),
      ),
    );
  }
}

class _PickerConfirmButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PickerConfirmButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isEnabled = onTap != null;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: isEnabled ? palette.primary : palette.primarySoft,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isEnabled ? Colors.white : palette.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
