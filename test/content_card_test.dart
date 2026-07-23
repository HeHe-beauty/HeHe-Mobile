import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hehe/models/content_item.dart';
import 'package:hehe/theme/app_theme.dart';
import 'package:hehe/widgets/content_card.dart';

void main() {
  testWidgets('shows the content icon on a recommendation card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: ContentCard(
            item: ContentItem(
              title: '추천 콘텐츠',
              markdownContent: null,
              icon: Icons.article_rounded,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.article_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
