import 'package:flutter/material.dart';

class ContentItem {
  final int? articleId;
  final String title;
  final String? subTitle;
  final String? thumbnailUrl;
  final String? htmlContent;
  final IconData icon;
  final String author;

  const ContentItem({
    this.articleId,
    required this.title,
    this.subTitle,
    this.thumbnailUrl,
    required this.htmlContent,
    required this.icon,
    required this.author,
  });
}
