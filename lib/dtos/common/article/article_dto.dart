class ArticleDto {
  final int articleId;
  final String title;
  final String thumbnailUrl;

  ArticleDto({
    required this.articleId,
    required this.title,
    required this.thumbnailUrl,
  });

  factory ArticleDto.fromJson(Map<String, dynamic> json) {
    return ArticleDto(
      articleId: json['articleId'] as int,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
    );
  }
}
