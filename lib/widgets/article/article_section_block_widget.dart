import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../models/article_content_block.dart';
import '../../theme/app_palette.dart';
import 'article_icon.dart';

class ArticleSectionBlockWidget extends StatelessWidget {
  final ArticleSectionBlock block;

  const ArticleSectionBlockWidget({super.key, required this.block});

  static final RegExp _orderedItem = RegExp(r'^\s*(\d+)\.\s+(.+)$');
  static final RegExp _unorderedItem = RegExp(r'^\s*-\s+(.+)$');

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final rows = _parseRows(block.body);

    return Padding(
      padding: const EdgeInsets.only(top: 9, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ArticleIcon(name: block.icon, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  block.title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...rows.indexed.map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.$1 == rows.length - 1 ? 0 : 11,
              ),
              child: _SectionRow(row: entry.$2),
            ),
          ),
        ],
      ),
    );
  }

  List<_SectionRowData> _parseRows(String body) {
    final rows = <_SectionRowData>[];
    final paragraph = <String>[];

    void flushParagraph() {
      final value = paragraph.join('\n').trim();
      if (value.isNotEmpty) rows.add(_SectionRowData.paragraph(value));
      paragraph.clear();
    }

    for (final line in body.split('\n')) {
      final unordered = _unorderedItem.firstMatch(line);
      final ordered = _orderedItem.firstMatch(line);
      if (unordered != null) {
        flushParagraph();
        rows.add(_SectionRowData.check(unordered.group(1)!));
      } else if (ordered != null) {
        flushParagraph();
        rows.add(
          _SectionRowData.numbered(ordered.group(1)!, ordered.group(2)!),
        );
      } else if (line.trim().isEmpty) {
        flushParagraph();
      } else {
        paragraph.add(line);
      }
    }
    flushParagraph();
    return rows;
  }
}

enum _SectionRowType { check, numbered, paragraph }

class _SectionRowData {
  final _SectionRowType type;
  final String text;
  final String? number;

  const _SectionRowData._(this.type, this.text, [this.number]);

  factory _SectionRowData.check(String text) =>
      _SectionRowData._(_SectionRowType.check, text);
  factory _SectionRowData.numbered(String number, String text) =>
      _SectionRowData._(_SectionRowType.numbered, text, number);
  factory _SectionRowData.paragraph(String text) =>
      _SectionRowData._(_SectionRowType.paragraph, text);
}

class _SectionRow extends StatelessWidget {
  final _SectionRowData row;

  const _SectionRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = TextStyle(
      color: palette.textSecondary,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.55,
      letterSpacing: -0.15,
    );

    if (row.type == _SectionRowType.paragraph) {
      return MarkdownBody(
        data: row.text,
        styleSheet: MarkdownStyleSheet(
          p: style,
          strong: style.copyWith(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          pPadding: EdgeInsets.zero,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: row.type == _SectionRowType.check
              ? const ArticleCheckCircleIcon()
              : ArticleNumberIcon(number: row.number!),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(row.text, style: style)),
      ],
    );
  }
}
