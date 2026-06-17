class ArticleDetailDto {
  final int articleId;
  final String title;
  final String content;

  ArticleDetailDto({
    required this.articleId,
    required this.title,
    required this.content,
  });

  factory ArticleDetailDto.fromJson(Map<String, dynamic> json) {
    return ArticleDetailDto(
      articleId: json['articleId'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }
}
