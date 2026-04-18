import 'package:flutter/material.dart';
import '../models/content_item.dart';
import '../theme/app_palette.dart';

class ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ContentCard({
    super.key,
    required this.item,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final resolvedBackgroundColor = backgroundColor ?? palette.surface;
    final resolvedForegroundColor = foregroundColor ?? palette.textPrimary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: resolvedBackgroundColor,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: _ContentThumbnail(item: item),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _WordWrappedTitle(
                    title: item.title,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: resolvedForegroundColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordWrappedTitle extends StatelessWidget {
  final String title;
  final TextStyle style;
  final TextAlign textAlign;

  const _WordWrappedTitle({
    required this.title,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final normalizedTitle = title.trim().replaceAll(RegExp(r'\s+'), ' ');
        final words = _splitWords(normalizedTitle);
        final lines = _wrapByWords(words, style, constraints.maxWidth, context);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: _crossAxisAlignmentFor(textAlign),
          children: [
            for (final line in lines)
              Align(
                alignment: _alignmentFor(textAlign),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: _alignmentFor(textAlign),
                  child: Text(
                    line,
                    textAlign: textAlign,
                    softWrap: false,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: style,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<String> _wrapByWords(
    List<String> words,
    TextStyle style,
    double maxWidth,
    BuildContext context,
  ) {
    if (words.isEmpty) return const [''];

    final lines = <String>[];
    var currentLine = '';

    for (final word in words) {
      final candidate = currentLine.isEmpty ? word : '$currentLine $word';
      if (currentLine.isEmpty || _fits(candidate, style, maxWidth, context)) {
        currentLine = candidate;
        continue;
      }

      lines.add(currentLine);
      currentLine = word;
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }

  CrossAxisAlignment _crossAxisAlignmentFor(TextAlign textAlign) {
    return switch (textAlign) {
      TextAlign.center => CrossAxisAlignment.center,
      TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.start,
    };
  }

  Alignment _alignmentFor(TextAlign textAlign) {
    return switch (textAlign) {
      TextAlign.center => Alignment.center,
      TextAlign.right || TextAlign.end => Alignment.centerRight,
      _ => Alignment.centerLeft,
    };
  }

  bool _fits(
    String text,
    TextStyle style,
    double maxWidth,
    BuildContext context,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout(maxWidth: maxWidth);

    return !painter.didExceedMaxLines;
  }

  List<String> _splitWords(String text) {
    final parts = text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final words = <String>[];

    for (final part in parts) {
      if (_isEmojiToken(part) && words.isNotEmpty) {
        words[words.length - 1] = '${words.last} $part';
        continue;
      }

      words.add(part);
    }

    return words;
  }

  bool _isEmojiToken(String text) {
    for (final rune in text.runes) {
      if (!_isEmojiRune(rune)) return false;
    }

    return text.isNotEmpty;
  }

  bool _isEmojiRune(int rune) {
    return rune == 0x200D ||
        rune == 0xFE0F ||
        (rune >= 0x1F000 && rune <= 0x1FAFF) ||
        (rune >= 0x2600 && rune <= 0x27BF);
  }
}

class _ContentThumbnail extends StatelessWidget {
  final ContentItem item;

  const _ContentThumbnail({required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final thumbnailUrl = item.thumbnailUrl;

    if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
      return Icon(item.icon, size: 22, color: palette.primary);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(item.icon, size: 22, color: palette.primary);
        },
      ),
    );
  }
}
