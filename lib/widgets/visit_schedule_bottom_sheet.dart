import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hehe/common/utils/app_time.dart';

import '../theme/app_palette.dart';

class VisitScheduleResult {
  final String hospitalName;
  final DateTime dateTime;

  const VisitScheduleResult({
    required this.hospitalName,
    required this.dateTime,
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
  static const double _datePickerViewportHeight = 98;
  static const double _timePickerViewportHeight = 98;
  static const double _selectedPillHeight = 36;

  late final TextEditingController _hospitalController;
  late final FocusNode _hospitalFocusNode;

  late final List<int> _years;
  late final List<int> _months;
  late final List<int> _hours;
  late final List<int> _minutes;

  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

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

  List<int> get _days => List.generate(
    _daysInMonth(_selectedYear, _selectedMonth),
    (index) => index + 1,
  );

  @override
  void initState() {
    super.initState();

    final now = AppTime.now();
    final initialDateTime = widget.initialDateTime ?? now;
    final minYear = now.year;
    final maxYear = math.max(now.year + 10, initialDateTime.year);

    _years = List.generate(maxYear - minYear + 1, (index) => minYear + index);
    _months = List.generate(12, (index) => index + 1);
    _hours = List.generate(24, (index) => index);
    _minutes = List.generate(60, (index) => index);

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

    _yearController = FixedExtentScrollController(
      initialItem: _years.indexOf(_selectedYear),
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  void dispose() {
    _hospitalController.removeListener(_onHospitalNameChanged);
    _hospitalController.dispose();
    _hospitalFocusNode.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
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
      dateTime: DateTime(
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

  void _onSelectedYear(int index) {
    final nextYear = _years[index];
    if (nextYear == _selectedYear) return;

    HapticFeedback.selectionClick();
    setState(() {
      _selectedYear = nextYear;
      _syncDaySelection();
    });
  }

  void _onSelectedMonth(int index) {
    final nextMonth = _months[index];
    if (nextMonth == _selectedMonth) return;

    HapticFeedback.selectionClick();
    setState(() {
      _selectedMonth = nextMonth;
      _syncDaySelection();
    });
  }

  void _onSelectedDay(int index) {
    final nextDay = _days[index];
    if (nextDay == _selectedDay) return;

    HapticFeedback.selectionClick();
    setState(() {
      _selectedDay = nextDay;
    });
  }

  void _syncDaySelection() {
    final maxDay = _daysInMonth(_selectedYear, _selectedMonth);
    if (_selectedDay <= maxDay) return;

    _selectedDay = maxDay;
    final previousController = _dayController;
    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    previousController.dispose();
  }

  Future<void> _openDatePicker() async {
    if (_isFixedDateMode) return;

    FocusManager.instance.primaryFocus?.unfocus();
    if (!_hasSelectedDate) {
      setState(() {
        _hasSelectedDate = true;
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: context.palette.modalBarrier,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            return _PickerSheetFrame(
              title: '언제 방문하세요?',
              child: _DatePickerRow(
                height: _datePickerViewportHeight,
                yearCard: _WheelPickerCard(
                  child: _WheelPickerColumn(
                    values: _years,
                    selectedValue: _selectedYear,
                    scrollController: _yearController,
                    onSelectedItemChanged: (index) {
                      _onSelectedYear(index);
                      setPickerState(() {});
                    },
                  ),
                ),
                monthCard: _WheelPickerCard(
                  child: _WheelPickerColumn(
                    values: _months,
                    selectedValue: _selectedMonth,
                    scrollController: _monthController,
                    onSelectedItemChanged: (index) {
                      _onSelectedMonth(index);
                      setPickerState(() {});
                    },
                  ),
                ),
                dayCard: _WheelPickerCard(
                  child: _WheelPickerColumn(
                    values: _days,
                    selectedValue: _selectedDay,
                    scrollController: _dayController,
                    onSelectedItemChanged: (index) {
                      _onSelectedDay(index);
                      setPickerState(() {});
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openTimePicker() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_hasSelectedTime) {
      setState(() {
        _hasSelectedTime = true;
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: context.palette.modalBarrier,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            return _PickerSheetFrame(
              title: '몇시에 방문하세요?',
              child: _TimePickerRow(
                height: _timePickerViewportHeight,
                hourCard: _WheelPickerCard(
                  child: _WheelPickerColumn(
                    values: _hours,
                    selectedValue: _selectedHour,
                    scrollController: _hourController,
                    onSelectedItemChanged: (index) {
                      final nextHour = _hours[index];
                      if (nextHour == _selectedHour) return;

                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedHour = nextHour;
                      });
                      setPickerState(() {});
                    },
                  ),
                ),
                minuteCard: _WheelPickerCard(
                  child: _WheelPickerColumn(
                    values: _minutes,
                    selectedValue: _selectedMinute,
                    scrollController: _minuteController,
                    onSelectedItemChanged: (index) {
                      final nextMinute = _minutes[index];
                      if (nextMinute == _selectedMinute) return;

                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedMinute = nextMinute;
                      });
                      setPickerState(() {});
                    },
                  ),
                ),
              ),
            );
          },
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
}

class _PickerSheetFrame extends StatelessWidget {
  final String title;
  final Widget child;

  const _PickerSheetFrame({required this.title, required this.child});

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
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
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

class _DatePickerRow extends StatelessWidget {
  final double height;
  final Widget yearCard;
  final Widget monthCard;
  final Widget dayCard;

  const _DatePickerRow({
    required this.height,
    required this.yearCard,
    required this.monthCard,
    required this.dayCard,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(flex: 2, child: yearCard),
          const SizedBox(width: 8),
          const _PickerUnitLabel('년'),
          const SizedBox(width: 8),
          Expanded(child: monthCard),
          const SizedBox(width: 8),
          const _PickerUnitLabel('월'),
          const SizedBox(width: 8),
          Expanded(child: dayCard),
          const SizedBox(width: 8),
          const _PickerUnitLabel('일'),
        ],
      ),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  final double height;
  final Widget hourCard;
  final Widget minuteCard;

  const _TimePickerRow({
    required this.height,
    required this.hourCard,
    required this.minuteCard,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(child: hourCard),
          const SizedBox(width: 10),
          const _PickerUnitLabel('시'),
          const SizedBox(width: 10),
          Expanded(child: minuteCard),
          const SizedBox(width: 10),
          const _PickerUnitLabel('분'),
        ],
      ),
    );
  }
}

class _PickerUnitLabel extends StatelessWidget {
  final String label;

  const _PickerUnitLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: palette.textPrimary,
        ),
      ),
    );
  }
}

class _WheelPickerCard extends StatelessWidget {
  final Widget child;

  const _WheelPickerCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.bottomSheetInnerSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.bottomSheetBorder),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: child),
    );
  }
}

class _WheelPickerColumn extends StatelessWidget {
  final List<int> values;
  final int selectedValue;
  final FixedExtentScrollController scrollController;
  final ValueChanged<int> onSelectedItemChanged;

  const _WheelPickerColumn({
    required this.values,
    required this.selectedValue,
    required this.scrollController,
    required this.onSelectedItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Center(
              child: Container(
                width: double.infinity,
                height: _VisitScheduleBottomSheetState._selectedPillHeight,
                decoration: BoxDecoration(
                  color: isDark
                      ? palette.primary.withValues(alpha: 0.52)
                      : palette.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: isDark
                      ? Border.all(
                          color: palette.primaryStrong.withValues(alpha: 0.42),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
        ListWheelScrollView.useDelegate(
          controller: scrollController,
          itemExtent: 26,
          diameterRatio: 3.2,
          perspective: 0.002,
          squeeze: 1.08,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: onSelectedItemChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: values.length,
            builder: (context, index) {
              final value = values[index];
              final isSelected = value == selectedValue;

              return Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  scale: isSelected ? 1.0 : 0.92,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    opacity: isSelected ? 1.0 : 0.68,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        fontSize: isSelected ? 16 : 12,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? isDark
                                  ? Colors.white
                                  : palette.textPrimary
                            : palette.textTertiary,
                      ),
                      child: Text(value.toString().padLeft(2, '0')),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
