class BookmarkDto {
  final int hospitalId;
  final String name;
  final String address;
  final List<String> tags;
  final DateTime? bookmarkedAt;

  const BookmarkDto({
    required this.hospitalId,
    required this.name,
    required this.address,
    required this.tags,
    required this.bookmarkedAt,
  });

  factory BookmarkDto.fromJson(Map<String, dynamic> json) {
    return BookmarkDto(
      hospitalId: json['hospitalId'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag as String)
          .toList(),
      bookmarkedAt: DateTime.tryParse(json['bookmarkedAt'] as String? ?? ''),
    );
  }
}
