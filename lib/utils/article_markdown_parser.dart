import '../models/article_content_block.dart';

class ArticleMarkdownParser {
  const ArticleMarkdownParser._();

  static final RegExp _openingPattern = RegExp(
    r'^:::(section|callout)(?:\s+(.*))?\s*$',
  );
  static final RegExp _closingPattern = RegExp(r'^:::\s*$');
  static final RegExp _attributePattern = RegExp(
    r'''([A-Za-z][A-Za-z0-9_-]*)\s*=\s*(["'])(.*?)\2''',
  );

  static List<ArticleContentBlock> parse(String source) {
    if (source.trim().isEmpty) return const [];

    final lines = source.replaceAll('\r\n', '\n').split('\n');
    final blocks = <ArticleContentBlock>[];
    final markdown = <String>[];

    void flushMarkdown() {
      final value = markdown.join('\n').trim();
      if (value.isNotEmpty) blocks.add(ArticleMarkdownBlock(value));
      markdown.clear();
    }

    var index = 0;
    while (index < lines.length) {
      final opening = _openingPattern.firstMatch(lines[index].trim());
      if (opening == null) {
        markdown.add(lines[index]);
        index++;
        continue;
      }

      var closingIndex = index + 1;
      while (closingIndex < lines.length &&
          !_closingPattern.hasMatch(lines[closingIndex].trim())) {
        closingIndex++;
      }

      if (closingIndex >= lines.length) {
        markdown.addAll(lines.sublist(index));
        break;
      }

      final type = opening.group(1)!;
      final attributesSource = opening.group(2)?.trim() ?? '';
      final attributes = _parseAttributes(attributesSource);
      final body = lines.sublist(index + 1, closingIndex).join('\n').trim();
      final isValid =
          _attributesAreValid(attributesSource, attributes) &&
          body.isNotEmpty &&
          (type == 'section'
              ? attributes['icon']?.isNotEmpty == true &&
                    attributes['title']?.isNotEmpty == true
              : attributes['icon']?.isNotEmpty == true);

      if (!isValid) {
        markdown.addAll(lines.sublist(index, closingIndex + 1));
        index = closingIndex + 1;
        continue;
      }

      flushMarkdown();
      if (type == 'section') {
        blocks.add(
          ArticleSectionBlock(
            icon: attributes['icon']!,
            title: attributes['title']!,
            body: body,
          ),
        );
      } else {
        blocks.add(ArticleCalloutBlock(icon: attributes['icon']!, body: body));
      }
      index = closingIndex + 1;
    }

    flushMarkdown();
    return blocks;
  }

  static Map<String, String> _parseAttributes(String source) {
    return {
      for (final match in _attributePattern.allMatches(source))
        match.group(1)!: match.group(3)!,
    };
  }

  static bool _attributesAreValid(
    String source,
    Map<String, String> attributes,
  ) {
    if (source.isEmpty || attributes.isEmpty) return false;
    final remainder = source.replaceAll(_attributePattern, '').trim();
    return remainder.isEmpty;
  }
}
