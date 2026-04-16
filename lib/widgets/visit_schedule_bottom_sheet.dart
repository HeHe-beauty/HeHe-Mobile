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

  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  late int _selectedHour;
  late int _selectedMinute;

  bool get _isFixedDateMode => widget.fixedDate != null;

  DateTime get _effectiveFixedDate => widget.fixedDate!;

  String get _fixedDateLabel {
    const weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];
    final date = _effectiveFixedDate;
    final weekday = weekdayLabels[date.weekday % 7];
    return '${date.year}년 ${date.month}월 ${date.day}일 $weekday요일';
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

    _hospitalController = TextEditingController(
      text: widget.initialHospitalName ?? '',
    );
    _hospitalFocusNode = FocusNode();

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
    _hospitalController.dispose();
    _hospitalFocusNode.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = VisitScheduleResult(
      hospitalName: _hospitalController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomPadding = mediaQuery.padding.bottom;
    final contentBottomPadding = math.max(bottomPadding, 12.0);

    return SafeArea(
      top: false,
      bottom: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, contentBottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 6,
                    decoration: BoxDecoration(
                      color: palette.bottomSheetBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title ?? '병원 방문 일정을 등록할까요?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '병원명',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                _CompactInputField(
                  controller: _hospitalController,
                  focusNode: _hospitalFocusNode,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 26),
                if (_isFixedDateMode) ...[
                  Text(
                    '선택한 날짜',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FixedDateCard(label: _fixedDateLabel),
                  const SizedBox(height: 26),
                ] else ...[
                  Text(
                    '언제 방문하세요?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DatePickerRow(
                    height: _datePickerViewportHeight,
                    yearCard: _WheelPickerCard(
                      child: _WheelPickerColumn(
                        values: _years,
                        selectedValue: _selectedYear,
                        scrollController: _yearController,
                        onSelectedItemChanged: _onSelectedYear,
                      ),
                    ),
                    monthCard: _WheelPickerCard(
                      child: _WheelPickerColumn(
                        values: _months,
                        selectedValue: _selectedMonth,
                        scrollController: _monthController,
                        onSelectedItemChanged: _onSelectedMonth,
                      ),
                    ),
                    dayCard: _WheelPickerCard(
                      child: _WheelPickerColumn(
                        values: _days,
                        selectedValue: _selectedDay,
                        scrollController: _dayController,
                        onSelectedItemChanged: _onSelectedDay,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                ],
                Text(
                  '몇시에 방문하세요?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _TimePickerRow(
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
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primarySoft,
                      foregroundColor: palette.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      widget.confirmLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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

class _FixedDateCard extends StatelessWidget {
  final String label;

  const _FixedDateCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.bottomSheetInnerSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.bottomSheetBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: palette.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  const _CompactInputField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: palette.bottomSheetInnerSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.bottomSheetBorder),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.done,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: '병원명을 입력해주세요',
          hintStyle: TextStyle(
            color: palette.textTertiary,
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
    );
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
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(16),
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
                            ? palette.textPrimary
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
