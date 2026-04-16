import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/content_item.dart';
import '../theme/app_palette.dart';
import '../widgets/app_icon_circle_button.dart';

class ContentDetailScreen extends StatelessWidget {
  final String title;
  final String? htmlContent;
  final IconData icon;

  ContentDetailScreen({super.key, required ContentItem item})
    : title = item.title,
      htmlContent = item.htmlContent,
      icon = item.icon;

  const ContentDetailScreen.content({
    super.key,
    required this.title,
    required this.htmlContent,
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
              Expanded(child: _ContentBodyArea(htmlContent: htmlContent ?? '')),
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
  final String htmlContent;

  const _ContentBodyArea({required this.htmlContent});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SingleChildScrollView(
      child: Html(
        data: htmlContent,
        shrinkWrap: true,
        style: {
          'html': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
          'body': Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            color: palette.textSecondary,
            fontSize: FontSize(12),
            fontWeight: FontWeight.w600,
            lineHeight: const LineHeight(1.6),
          ),
          'p': Style(
            margin: Margins.only(bottom: 16),
            padding: HtmlPaddings.zero,
          ),
          'strong': Style(
            color: palette.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          'b': Style(color: palette.textPrimary, fontWeight: FontWeight.w800),
        },
      ),
    );
  }
}
