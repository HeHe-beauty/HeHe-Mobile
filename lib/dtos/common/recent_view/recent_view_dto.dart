class RecentViewDto {
  final int hospitalId;
  final String name;
  final String address;
  final List<String> tags;
  final DateTime? viewedAt;

  const RecentViewDto({
    required this.hospitalId,
    required this.name,
    required this.address,
    required this.tags,
    required this.viewedAt,
  });

  factory RecentViewDto.fromJson(Map<String, dynamic> json) {
    return RecentViewDto(
      hospitalId: json['hospitalId'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag as String)
          .toList(),
      viewedAt: DateTime.tryParse(json['viewedAt'] as String? ?? ''),
    );
  }
}
