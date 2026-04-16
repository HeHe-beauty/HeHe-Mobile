import 'package:flutter/material.dart';
import '../models/content_item.dart';
import '../theme/app_palette.dart';

class ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback? onTap;

  const ContentCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: _ContentThumbnail(item: item),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _WordWrappedTitle(
                      title: item.title,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.4,
                        color: palette.textPrimary,
                      ),
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
        final words = normalizedTitle.split(' ');

        if (words.length <= 1) {
          return Text(
            normalizedTitle,
            textAlign: textAlign,
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          );
        }

        final lines = <String>[];
        var currentLine = '';

        for (final word in words) {
          final candidate = currentLine.isEmpty ? word : '$currentLine $word';
          if (_fits(candidate, style, constraints.maxWidth, context)) {
            currentLine = candidate;
            continue;
          }

          if (currentLine.isNotEmpty) {
            lines.add(currentLine);
            if (lines.length == 2) {
              break;
            }
          }

          currentLine = word;
        }

        if (lines.length < 2 && currentLine.isNotEmpty) {
          lines.add(currentLine);
        }

        if (lines.isEmpty) {
          lines.add(normalizedTitle);
        }

        if (lines.length > 2) {
          lines.removeRange(2, lines.length);
        }

        final consumedWords = lines
            .expand((line) => line.split(' '))
            .where((word) => word.isNotEmpty)
            .length;

        if (consumedWords < words.length) {
          final remaining = words.sublist(consumedWords).join(' ');
          final finalLineBase = lines.length == 2
              ? lines.removeLast()
              : (lines.isNotEmpty ? lines.removeLast() : '');
          final finalLine = [
            finalLineBase,
            remaining,
          ].where((part) => part.isNotEmpty).join(' ');
          lines.add(
            _ellipsizeToWidth(finalLine, style, constraints.maxWidth, context),
          );
        } else {
          final lastLine = lines.removeLast();
          lines.add(
            _ellipsizeToWidth(lastLine, style, constraints.maxWidth, context),
          );
        }

        return Text(
          lines.join('\n'),
          textAlign: textAlign,
          softWrap: false,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
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

  String _ellipsizeToWidth(
    String text,
    TextStyle style,
    double maxWidth,
    BuildContext context,
  ) {
    if (_fits(text, style, maxWidth, context)) {
      return text;
    }

    final parts = text
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '…';

    var low = 0;
    var high = parts.length;
    var best = '';

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final candidate = '${parts.take(mid).join(' ')}…';
      if (_fits(candidate, style, maxWidth, context)) {
        best = candidate;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return best.isEmpty ? '…' : best;
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
      return Icon(item.icon, size: 28, color: palette.primary);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(item.icon, size: 28, color: palette.primary);
        },
      ),
    );
  }
}
