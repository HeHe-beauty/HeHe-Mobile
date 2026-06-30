enum ArticleContentBlockType { markdown, section, callout }

abstract class ArticleContentBlock {
  const ArticleContentBlock();

  ArticleContentBlockType get type;
}

class ArticleMarkdownBlock extends ArticleContentBlock {
  final String markdown;

  const ArticleMarkdownBlock(this.markdown);

  @override
  ArticleContentBlockType get type => ArticleContentBlockType.markdown;
}

class ArticleSectionBlock extends ArticleContentBlock {
  final String icon;
  final String title;
  final String body;

  const ArticleSectionBlock({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  ArticleContentBlockType get type => ArticleContentBlockType.section;
}

class ArticleCalloutBlock extends ArticleContentBlock {
  final String icon;
  final String body;

  const ArticleCalloutBlock({required this.icon, required this.body});

  @override
  ArticleContentBlockType get type => ArticleContentBlockType.callout;
}
