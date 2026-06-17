import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/content_item.dart';
import '../theme/app_palette.dart';
import '../widgets/app_icon_circle_button.dart';

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
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          color: palette.bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ContentHeader(
                title: title,
                icon: icon,
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _ContentBodyArea(markdownContent: markdownContent ?? ''),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onClose;

  const _ContentHeader({
    required this.title,
    required this.icon,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(icon, size: 20, color: palette.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.35,
              color: palette.textPrimary,
            ),
          ),
        ),
        AppIconCircleButton(icon: Icons.close_rounded, onTap: onClose),
      ],
    );
  }
}

class _ContentBodyArea extends StatelessWidget {
  final String markdownContent;

  const _ContentBodyArea({required this.markdownContent});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final bodyStyle = TextStyle(
      color: palette.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.6,
    );

    return Markdown(
      data: markdownContent,
      padding: EdgeInsets.zero,
      styleSheet: MarkdownStyleSheet(
        p: bodyStyle,
        strong: bodyStyle.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        h1: TextStyle(
          color: palette.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          height: 1.3,
        ),
        h2: TextStyle(
          color: palette.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          height: 1.35,
        ),
        h3: TextStyle(
          color: palette.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          height: 1.4,
        ),
        listBullet: bodyStyle,
        blockquote: bodyStyle.copyWith(color: palette.textTertiary),
        blockquoteDecoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: palette.border, width: 3)),
        ),
      ),
    );
  }
}
