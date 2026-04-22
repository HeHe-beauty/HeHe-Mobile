class ContactDto {
  final int id;
  final int hospitalId;
  final String hospitalName;
  final String contactType;
  final DateTime? createdAt;

  const ContactDto({
    required this.id,
    required this.hospitalId,
    required this.hospitalName,
    required this.contactType,
    required this.createdAt,
  });

  factory ContactDto.fromJson(Map<String, dynamic> json) {
    return ContactDto(
      id: json['id'] as int,
      hospitalId: json['hospitalId'] as int,
      hospitalName: json['hospitalName'] as String,
      contactType: json['contactType'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
