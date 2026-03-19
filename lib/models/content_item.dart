import 'package:flutter/material.dart';

class ContentItem {
  final String title;
  final String body;
  final IconData icon;
  final String author;

  const ContentItem({
    required this.title,
    required this.body,
    required this.icon,
    required this.author,
  });
}