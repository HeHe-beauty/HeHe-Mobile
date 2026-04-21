import 'package:flutter/material.dart';
import '../models/content_item.dart';
import '../theme/app_palette.dart';
import '../utils/word_wrap_utils.dart';

class ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? thumbnailBackgroundColor;

  const ContentCard({
    super.key,
    required this.item,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.thumbnailBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final resolvedBackgroundColor = backgroundColor ?? palette.surface;
    final resolvedForegroundColor = foregroundColor ?? palette.textPrimary;
    final resolvedThumbnailBackgroundColor =
        thumbnailBackgroundColor ?? palette.surfaceMuted;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
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
                  color: resolvedThumbnailBackgroundColor,
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
        final lines = wrapTextByWords(
          title,
          style,
          constraints.maxWidth,
          context,
          attachEmojiToPreviousWord: true,
        );

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
}

class _ContentThumbnail extends StatelessWidget {
  final ContentItem item;

  const _ContentThumbnail({required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final thumbnailUrl = item.thumbnailUrl;

    if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
      return Icon(item.icon, size: 22, color: palette.primaryStrong);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(item.icon, size: 22, color: palette.primaryStrong);
        },
      ),
    );
  }
}
