import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hehe/main.dart';
import 'package:hehe/screens/content_detail_screen.dart';
import 'package:hehe/theme/app_theme.dart';

void main() {
  testWidgets('shows splash screen and navigates to home', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('HeHe'), findsOneWidget);
    expect(find.text('나에게 맞는 선택을 더 쉽게'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('추천 콘텐츠'), findsOneWidget);
    expect(
      find.textContaining('관리는 HeHe에서', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('renders content detail body from html', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ContentDetailScreen.content(
          sourceLabel: 'HeHe',
          title: 'HTML 렌더링 테스트',
          htmlContent:
              '<html><body><p><strong>기존 내용</strong></p></body></html>',
        ),
      ),
    );

    expect(find.text('HTML 렌더링 테스트'), findsOneWidget);
    expect(find.textContaining('기존 내용', findRichText: true), findsOneWidget);
    expect(find.textContaining('<html>', findRichText: true), findsNothing);
  });
}
