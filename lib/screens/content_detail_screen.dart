import 'package:flutter/material.dart';
import '../dtos/common/article/article_detail_dto.dart';
import '../models/content_item.dart';
import 'article_detail_screen.dart';

class ContentDetailScreen extends StatelessWidget {
  final String title;
  final String? markdownContent;
  final IconData icon;

  ContentDetailScreen({super.key, required ContentItem item})
    : title = item.title,
      markdownContent = item.markdownContent,
      icon = item.icon;

  const ContentDetailScreen.markdown({
    super.key,
    required this.title,
    required this.markdownContent,
    this.icon = Icons.article_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return ArticleDetailScreen.data(
      article: ArticleDetailDto(
        articleId: 0,
        title: title,
        content: markdownContent ?? '',
      ),
    );
  }
}
