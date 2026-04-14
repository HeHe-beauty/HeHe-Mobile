class HospitalEquipmentDto {
  final String modelName;
  final int totalCount;

  HospitalEquipmentDto({required this.modelName, required this.totalCount});

  factory HospitalEquipmentDto.fromJson(Map<String, dynamic> json) {
    return HospitalEquipmentDto(
      modelName: json['modelName'] as String,
      totalCount: json['totalCount'] as int,
    );
  }
}
