import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class AddScheduleBottomSheet extends StatefulWidget {
  const AddScheduleBottomSheet({super.key});

  @override
  State<AddScheduleBottomSheet> createState() => _AddScheduleBottomSheetState();
}

class _AddScheduleBottomSheetState extends State<AddScheduleBottomSheet> {
  final TextEditingController _hospitalController = TextEditingController();
  final FocusNode _hospitalFocusNode = FocusNode();

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  int selectedHour = 7;
  int selectedMinute = 0;

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(initialItem: selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: selectedMinute);
  }

  @override
  void dispose() {
    _hospitalController.dispose();
    _hospitalFocusNode.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _submit() {
    final navigator = Navigator.of(context);
    final hospital = _hospitalController.text.trim();

    FocusManager.instance.primaryFocus?.unfocus();

    navigator.pop({
      'hospital': hospital,
      'hour': selectedHour,
      'minute': selectedMinute,
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hours = List.generate(24, (index) => index);
    final minutes = List.generate(60, (index) => index);

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.62,
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 6,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              '어느 병원을 방문하세요?',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.border),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _hospitalController,
                focusNode: _hospitalFocusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: '병원명을 입력해주세요',
                  hintStyle: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 34),
            Text(
              '언제 방문하세요?',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _WheelPickerBox(
                    child: CupertinoPicker(
                      itemExtent: 42,
                      diameterRatio: 1.25,
                      squeeze: 1.15,
                      useMagnifier: true,
                      magnification: 1.05,
                      scrollController: _hourController,
                      selectionOverlay: const SizedBox.shrink(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          selectedHour = hours[index];
                        });
                      },
                      children: hours
                          .map(
                            (hour) => Center(
                          child: Text(
                            hour.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: hour == selectedHour ? 26 : 20,
                              fontWeight: hour == selectedHour
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: hour == selectedHour
                                  ? palette.textPrimary
                                  : palette.textTertiary,
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '시',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _WheelPickerBox(
                    child: CupertinoPicker(
                      itemExtent: 42,
                      diameterRatio: 1.25,
                      squeeze: 1.15,
                      useMagnifier: true,
                      magnification: 1.05,
                      scrollController: _minuteController,
                      selectionOverlay: const SizedBox.shrink(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          selectedMinute = minutes[index];
                        });
                      },
                      children: minutes
                          .map(
                            (minute) => Center(
                          child: Text(
                            minute.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: minute == selectedMinute ? 26 : 20,
                              fontWeight: minute == selectedMinute
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: minute == selectedMinute
                                  ? palette.textPrimary
                                  : palette.textTertiary,
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '분',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primarySoft,
                  foregroundColor: palette.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  '완료',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPickerBox extends StatelessWidget {
  final Widget child;

  const _WheelPickerBox({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              height: 50,
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}