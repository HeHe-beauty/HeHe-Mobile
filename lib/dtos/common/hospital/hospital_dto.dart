class HospitalDto {
  final int hospitalId;
  final String name;
  final String address;
  final List<String> tags;
  final bool isBookmarked;
  final int bookmarkCount;

  HospitalDto({
    required this.hospitalId,
    required this.name,
    required this.address,
    required this.tags,
    required this.isBookmarked,
    required this.bookmarkCount,
  });

  factory HospitalDto.fromJson(Map<String, dynamic> json) {
    return HospitalDto(
      hospitalId: json['hospitalId'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      bookmarkCount: json['bookmarkCount'] as int? ?? 0,
    );
  }
}
