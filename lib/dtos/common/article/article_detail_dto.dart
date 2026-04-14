class ArticleDetailDto {
  final int articleId;
  final String title;
  final String subTitle;
  final String thumbnailUrl;
  final String content;

  ArticleDetailDto({
    required this.articleId,
    required this.title,
    required this.subTitle,
    required this.thumbnailUrl,
    required this.content,
  });

  factory ArticleDetailDto.fromJson(Map<String, dynamic> json) {
    return ArticleDetailDto(
      articleId: json['articleId'] as int,
      title: json['title'] as String,
      subTitle: json['subTitle'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      content: json['content'] as String,
    );
  }
}
