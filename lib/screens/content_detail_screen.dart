import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/content_item.dart';
import '../theme/app_palette.dart';
import '../widgets/app_icon_circle_button.dart';

class ContentDetailScreen extends StatelessWidget {
  final String sourceLabel;
  final String title;
  final String? htmlContent;
  final IconData icon;

  ContentDetailScreen({super.key, required ContentItem item})
    : sourceLabel = item.author,
      title = item.title,
      htmlContent = item.htmlContent,
      icon = item.icon;

  const ContentDetailScreen.content({
    super.key,
    required this.sourceLabel,
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
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ContentHeader(
                sourceLabel: sourceLabel,
                icon: icon,
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: 28),
              _ContentTitle(title: title),
              const SizedBox(height: 22),
              const _ContentDivider(),
              const SizedBox(height: 22),
              Expanded(child: _ContentBodyArea(htmlContent: htmlContent ?? '')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentHeader extends StatelessWidget {
  final String sourceLabel;
  final IconData icon;
  final VoidCallback onClose;

  const _ContentHeader({
    required this.sourceLabel,
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
            sourceLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
        ),
        AppIconCircleButton(
          icon: Icons.close_rounded,
          size: 44,
          iconSize: 22,
          showBorder: false,
          showShadow: false,
          backgroundColor: palette.surfaceSoft,
          onTap: onClose,
        ),
      ],
    );
  }
}

class _ContentTitle extends StatelessWidget {
  final String title;

  const _ContentTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        height: 1.4,
        color: palette.textPrimary,
      ),
    );
  }
}

class _ContentDivider extends StatelessWidget {
  const _ContentDivider();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: 120,
      height: 3,
      decoration: BoxDecoration(
        color: palette.border,
        borderRadius: BorderRadius.circular(999),
      ),
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
