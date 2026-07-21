import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../models/article_content_block.dart';
import '../../theme/app_palette.dart';
import 'article_icon.dart';

class ArticleCalloutBlockWidget extends StatelessWidget {
  final ArticleCalloutBlock block;

  const ArticleCalloutBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bodyStyle = TextStyle(
      color: palette.textSecondary,
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      height: 1.55,
      letterSpacing: -0.1,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 7, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
      decoration: BoxDecoration(
        color: palette.primarySoft.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ArticleIcon(name: block.icon, size: 27),
          const SizedBox(width: 14),
          Expanded(
            child: MarkdownBody(
              data: block.body,
              styleSheet: MarkdownStyleSheet(
                p: bodyStyle,
                strong: bodyStyle.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                pPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
