import 'hospital_map_cluster_dto.dart';

class HospitalMapDto {
  final int precision;
  final List<HospitalMapClusterDto> items;

  HospitalMapDto({required this.precision, required this.items});

  factory HospitalMapDto.fromJson(Map<String, dynamic> json) {
    return HospitalMapDto(
      precision: json['precision'] as int,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => HospitalMapClusterDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
