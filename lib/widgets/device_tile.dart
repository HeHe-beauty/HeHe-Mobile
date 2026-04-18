import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

const _homeSecondaryTextColor = Color(0xFF6B7280);

class DeviceTile extends StatelessWidget {
  final String title;
  final String description;
  final String? imageAsset;
  final double height;
  final VoidCallback? onTap;

  const DeviceTile({
    super.key,
    required this.title,
    required this.description,
    this.imageAsset,
    required this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: height,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 0,
                bottom: 0,
                child: SizedBox(
                  width: 42,
                  height: height - 42,
                  child: Image.asset(
                    imageAsset!,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 38,
                top: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title.replaceAll(RegExp(r'\s+'), ' '),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          letterSpacing: -0.2,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    _DeviceTileDescriptionText(
                      description,
                      style: TextStyle(
                        color: _homeSecondaryTextColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceTileDescriptionText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _DeviceTileDescriptionText(this.text, {required this.style});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final lines = _wordWrapLines(
          text.trim().replaceAll(RegExp(r'\s+'), ' '),
          style,
          constraints.maxWidth,
          context,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Text(
                line,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: style,
              ),
          ],
        );
      },
    );
  }
}

List<String> _wordWrapLines(
  String text,
  TextStyle style,
  double maxWidth,
  BuildContext context,
) {
  final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  final lines = <String>[];
  var currentLine = '';

  for (final word in words) {
    final candidate = currentLine.isEmpty ? word : '$currentLine $word';
    if (currentLine.isEmpty || _textFits(candidate, style, maxWidth, context)) {
      currentLine = candidate;
      continue;
    }

    lines.add(currentLine);
    currentLine = word;
  }

  if (currentLine.isNotEmpty) {
    lines.add(currentLine);
  }

  return lines.isEmpty ? const [''] : lines;
}

bool _textFits(
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
