import 'package:flutter/material.dart';

class ContentItem {
  final int? articleId;
  final String title;
  final String? markdownContent;
  final IconData icon;

  const ContentItem({
    this.articleId,
    required this.title,
    required this.markdownContent,
    required this.icon,
  });
}
