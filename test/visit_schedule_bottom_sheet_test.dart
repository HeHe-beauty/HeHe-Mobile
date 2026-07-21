import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hehe/theme/app_theme.dart';
import 'package:hehe/widgets/visit_schedule_bottom_sheet.dart';

void main() {
  Widget buildSheet({String? confirmLabel}) {
    final sheet = confirmLabel == null
        ? VisitScheduleBottomSheet(
            initialDateTime: DateTime(2030, 7, 21, 14),
            initialHospitalName: '테스트 병원',
          )
        : VisitScheduleBottomSheet(
            initialDateTime: DateTime(2030, 7, 21, 14),
            initialHospitalName: '테스트 병원',
            confirmLabel: confirmLabel,
          );

    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: sheet),
    );
  }

  testWidgets('새 일정 시트는 등록하기 버튼을 표시한다', (tester) async {
    await tester.pumpWidget(buildSheet());

    expect(find.text('등록하기'), findsOneWidget);
    expect(find.text('수정하기'), findsNothing);
  });

  testWidgets('일정 수정 시트는 전달받은 수정하기 버튼을 표시한다', (tester) async {
    await tester.pumpWidget(buildSheet(confirmLabel: '수정하기'));

    expect(find.text('수정하기'), findsOneWidget);
    expect(find.text('등록하기'), findsNothing);
  });
}
