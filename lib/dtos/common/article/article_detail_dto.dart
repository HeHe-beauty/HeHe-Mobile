class ArticleDetailDto {
  final int articleId;
  final String title;
  final String? subTitle;
  final String? thumbnailUrl;
  final String content;
  final List<String> tags;
  final String? createdAt;
  final String? updatedAt;

  const ArticleDetailDto({
    required this.articleId,
    required this.title,
    this.subTitle,
    this.thumbnailUrl,
    required this.content,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ArticleDetailDto.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];

    return ArticleDetailDto(
      articleId: (json['articleId'] as num).toInt(),
      title: json['title'] as String? ?? '',
      subTitle: _nullableString(json['subTitle']),
      thumbnailUrl: _nullableString(json['thumbnailUrl']),
      content: json['content'] as String? ?? '',
      tags: rawTags is List
          ? rawTags
                .whereType<String>()
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList()
          : const [],
      createdAt: _nullableString(json['createdAt']),
      updatedAt: _nullableString(json['updatedAt']),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value;
  }
}
