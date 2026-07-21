import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../models/article_content_block.dart';
import '../../theme/app_palette.dart';
import '../../utils/article_markdown_parser.dart';
import 'article_callout_block_widget.dart';
import 'article_section_block_widget.dart';

class ArticleContentRenderer extends StatelessWidget {
  final String content;

  const ArticleContentRenderer({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final blocks = ArticleMarkdownParser.parse(content);
    if (blocks.isEmpty) {
      return _EmptyArticleContent();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks) ...[
          _buildBlock(context, block),
          if (!identical(block, blocks.last)) const SizedBox(height: 22),
        ],
      ],
    );
  }

  Widget _buildBlock(BuildContext context, ArticleContentBlock block) {
    return switch (block) {
      ArticleMarkdownBlock() => _ArticleMarkdown(block: block),
      ArticleSectionBlock() => ArticleSectionBlockWidget(block: block),
      ArticleCalloutBlock() => ArticleCalloutBlockWidget(block: block),
      _ => const SizedBox.shrink(),
    };
  }
}

class _ArticleMarkdown extends StatelessWidget {
  final ArticleMarkdownBlock block;

  const _ArticleMarkdown({required this.block});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final body = TextStyle(
      color: palette.textSecondary,
      fontSize: 15.5,
      fontWeight: FontWeight.w500,
      height: 1.65,
      letterSpacing: -0.15,
    );

    return MarkdownBody(
      data: block.markdown,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        p: body,
        pPadding: const EdgeInsets.only(bottom: 14),
        strong: body.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        em: body.copyWith(fontStyle: FontStyle.italic),
        h1: _headingStyle(palette, 24),
        h1Padding: const EdgeInsets.only(top: 4, bottom: 10),
        h2: _headingStyle(palette, 20),
        h2Padding: const EdgeInsets.only(top: 4, bottom: 9),
        h3: _headingStyle(palette, 18),
        h3Padding: const EdgeInsets.only(top: 2, bottom: 8),
        listBullet: body.copyWith(color: palette.primary),
        listIndent: 22,
        blockSpacing: 10,
        blockquote: body,
        blockquotePadding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        blockquoteDecoration: BoxDecoration(
          color: palette.surfaceSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: palette.primary, width: 3)),
        ),
      ),
    );
  }

  TextStyle _headingStyle(AppPalette palette, double size) => TextStyle(
    color: palette.textPrimary,
    fontSize: size,
    fontWeight: FontWeight.w800,
    height: 1.35,
    letterSpacing: -0.35,
  );
}

class _EmptyArticleContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          '아직 등록된 내용이 없어요.',
          style: TextStyle(color: palette.textTertiary, fontSize: 15),
        ),
      ),
    );
  }
}
