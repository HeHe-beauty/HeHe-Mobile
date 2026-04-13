import 'package:flutter/material.dart';

class ContentItem {
  final String title;
  final String htmlContent;
  final IconData icon;
  final String author;

  const ContentItem({
    required this.title,
    required this.htmlContent,
    required this.icon,
    required this.author,
  });
}
