class ContactDto {
  final int id;
  final int hospitalId;
  final String hospitalName;
  final String address;
  final List<String> tags;
  final String contactType;
  final bool isBookmarked;
  final DateTime? createdAt;

  const ContactDto({
    required this.id,
    required this.hospitalId,
    required this.hospitalName,
    required this.address,
    required this.tags,
    required this.contactType,
    required this.isBookmarked,
    required this.createdAt,
  });

  factory ContactDto.fromJson(Map<String, dynamic> json) {
    return ContactDto(
      id: json['id'] as int,
      hospitalId: json['hospitalId'] as int,
      hospitalName: json['hospitalName'] as String,
      address: json['address'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag as String)
          .toList(),
      contactType: json['contactType'] as String,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
