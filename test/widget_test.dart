import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hehe/dtos/common/article/article_detail_dto.dart';
import 'package:hehe/screens/article_detail_screen.dart';
import 'package:hehe/screens/content_detail_screen.dart';
import 'package:hehe/screens/splash_screen.dart';
import 'package:hehe/theme/app_theme.dart';
import 'package:hehe/widgets/article/article_content_renderer.dart';
import 'package:hehe/widgets/article/article_icon.dart';

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

  testWidgets('shows article detail tags as badges', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ArticleDetailScreen.data(
          article: ArticleDetailDto(
            articleId: 1,
            title: '레이저 제모하면 피부도 좋아질까?',
            thumbnailUrl: '',
            content: '본문',
            tags: ['레이저제모', '모공', '피부'],
          ),
        ),
      ),
    );

    expect(find.text('레이저 제모하면 피부도 좋아질까?'), findsOneWidget);
    expect(find.text('레이저제모'), findsOneWidget);
    expect(find.text('모공'), findsOneWidget);
    expect(find.text('피부'), findsOneWidget);
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

  testWidgets('renders all semantic custom section icons', (tester) async {
    const icons = {
      'shield': Icons.verified_user_rounded,
      'cycle': Icons.autorenew_rounded,
      'beard': Icons.face_6_rounded,
      'gauge': Icons.speed_rounded,
      'checklist': Icons.fact_check_rounded,
      'heart': Icons.favorite_rounded,
      'map': Icons.map_rounded,
      'equipment': Icons.biotech_rounded,
      'location': Icons.location_city_rounded,
      'door': Icons.meeting_room_rounded,
      'aftercare': Icons.healing_rounded,
      'link': Icons.link_rounded,
      'pin': Icons.location_on_rounded,
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Column(
            children: icons.keys
                .map((name) => ArticleIcon(name: name))
                .toList(),
          ),
        ),
      ),
    );

    for (final icon in icons.values) {
      expect(find.byIcon(icon), findsOneWidget);
    }
  });
}
