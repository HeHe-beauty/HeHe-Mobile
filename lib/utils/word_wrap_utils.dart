import 'package:flutter/material.dart';

List<String> wrapTextByWords(
  String text,
  TextStyle style,
  double maxWidth,
  BuildContext context, {
  bool attachEmojiToPreviousWord = false,
}) {
  final normalizedText = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  final words = _splitWords(
    normalizedText,
    attachEmojiToPreviousWord: attachEmojiToPreviousWord,
  );
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

List<String> _splitWords(
  String text, {
  required bool attachEmojiToPreviousWord,
}) {
  final parts = text
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  if (!attachEmojiToPreviousWord) return parts;

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
