class HospitalMapClusterDto {
  final int count;
  final double lat;
  final double lng;

  HospitalMapClusterDto({
    required this.count,
    required this.lat,
    required this.lng,
  });

  factory HospitalMapClusterDto.fromJson(Map<String, dynamic> json) {
    return HospitalMapClusterDto(
      count: json['count'] as int,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}
