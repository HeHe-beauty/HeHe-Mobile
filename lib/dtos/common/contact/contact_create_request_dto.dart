class ContactCreateRequestDto {
  final int hospitalId;
  final String contactType;

  const ContactCreateRequestDto({
    required this.hospitalId,
    required this.contactType,
  });

  Map<String, dynamic> toJson() {
    return {'hospitalId': hospitalId, 'contactType': contactType};
  }
}
