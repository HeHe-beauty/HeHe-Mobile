import 'package:flutter/material.dart';

class ContentItem {
  final int? articleId;
  final String title;
  final String? subTitle;
  final String? thumbnailUrl;
  final String? markdownContent;
  final IconData icon;
  final String author;

  const ContentItem({
    this.articleId,
    required this.title,
    this.subTitle,
    this.thumbnailUrl,
    required this.markdownContent,
    required this.icon,
    required this.author,
  });
}
