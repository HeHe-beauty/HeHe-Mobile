import 'package:flutter_test/flutter_test.dart';
import 'package:hehe/models/article_content_block.dart';
import 'package:hehe/utils/article_markdown_parser.dart';

void main() {
  const content = '''
첫 번째 문단입니다.

:::section icon="note" title="기대할 수 있는 변화"
- 피부가 매끈해 보여요.
- 피부가 편안해져요.
:::

중간 **강조 문단**입니다.

:::callout icon="sparkle"
전문의와 상담 후 진행하는 것이 좋아요.
:::
''';

  test('parses markdown, section, and callout blocks in order', () {
    final blocks = ArticleMarkdownParser.parse(content);

    expect(blocks, hasLength(4));
    expect(blocks[0], isA<ArticleMarkdownBlock>());
    expect(blocks[1], isA<ArticleSectionBlock>());
    expect((blocks[1] as ArticleSectionBlock).title, '기대할 수 있는 변화');
    expect(blocks[2], isA<ArticleMarkdownBlock>());
    expect(blocks[3], isA<ArticleCalloutBlock>());
  });

  test('falls back to markdown for malformed custom blocks', () {
    const malformed = '''
앞 문단
:::section icon="note"
- 제목 속성이 없어요.
:::
뒤 문단
''';

    final blocks = ArticleMarkdownParser.parse(malformed);

    expect(blocks, hasLength(1));
    expect(blocks.single, isA<ArticleMarkdownBlock>());
    expect(
      (blocks.single as ArticleMarkdownBlock).markdown,
      contains(':::section'),
    );
  });

  test('preserves an unknown block as markdown', () {
    const unknown = ''':::gallery columns="2"
image content
:::''';

    final blocks = ArticleMarkdownParser.parse(unknown);

    expect(blocks, hasLength(1));
    expect(blocks.single, isA<ArticleMarkdownBlock>());
  });
}
