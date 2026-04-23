import 'hospital_equipment_dto.dart';

class HospitalDetailDto {
  final int hospitalId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String contactNumber;
  final String contactUrl;
  final List<String> tags;
  final List<HospitalEquipmentDto> equipments;
  final bool isBookmarked;

  HospitalDetailDto({
    required this.hospitalId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.contactNumber,
    required this.contactUrl,
    required this.tags,
    required this.equipments,
    required this.isBookmarked,
  });

  factory HospitalDetailDto.fromJson(Map<String, dynamic> json) {
    return HospitalDetailDto(
      hospitalId: json['hospitalId'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      contactNumber: json['contactNumber'] as String,
      contactUrl: json['contactUrl'] as String,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      equipments: (json['equipments'] as List<dynamic>? ?? const [])
          .map((e) => HospitalEquipmentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );
  }
}
