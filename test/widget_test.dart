import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hehe/screens/content_detail_screen.dart';
import 'package:hehe/screens/splash_screen.dart';
import 'package:hehe/theme/app_theme.dart';
import 'package:hehe/widgets/article/article_content_renderer.dart';

void main() {
  testWidgets('shows splash screen and navigates to home', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const SplashScreen()),
    );

    expect(find.text('HeHe'), findsOneWidget);
    expect(find.text('나에게 맞는 선택을 더 쉽게'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('추천 콘텐츠'), findsOneWidget);
    expect(
      find.textContaining('기기를 선택하면 주변 병원 위치를 확인할 수 있어요', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('renders content detail body from markdown', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ContentDetailScreen.markdown(
          title: 'Markdown 렌더링 테스트',
          markdownContent: '**기존 내용**',
        ),
      ),
    );

    expect(find.text('Markdown 렌더링 테스트'), findsOneWidget);
    expect(find.textContaining('기존 내용', findRichText: true), findsOneWidget);
    expect(find.textContaining('**', findRichText: true), findsNothing);
  });

  testWidgets('renders custom article blocks as native widgets', (
    tester,
  ) async {
    const content = '''
:::section icon="note" title="기대할 수 있는 변화"
- 피부가 매끈해 보여요.
:::
:::section icon="bulb" title="이렇게 관리해보세요"
1. 보습제를 충분히 발라요.
:::
:::callout icon="sparkle"
전문의와 상담 후 진행하세요.
:::
''';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: ArticleContentRenderer(content: content),
          ),
        ),
      ),
    );

    expect(find.text('기대할 수 있는 변화'), findsOneWidget);
    expect(find.text('이렇게 관리해보세요'), findsOneWidget);
    expect(find.text('피부가 매끈해 보여요.'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.textContaining(':::section'), findsNothing);
  });
}
