import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'hospital_detail_dto.dart';
import 'hospital_dto.dart';
import 'hospital_map_dto.dart';

class HospitalApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<List<HospitalDto>> fetchHospitalList({
    required double lat,
    required double lng,
    required int precision,
    int? equipId,
    String? accessToken,
  }) async {
    final queryParameters = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'precision': precision,
    };

    if (equipId != null) {
      queryParameters['equipId'] = equipId;
    }

    final body = await _apiClient.get(
      ApiEndpoints.hospitalList,
      queryParameters: queryParameters,
      headers: accessToken == null || accessToken.isEmpty
          ? null
          : ApiClient.bearerHeaders(accessToken),
    );

    final data = body['data'] as List<dynamic>;

    return data
        .map((e) => HospitalDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<HospitalDetailDto> fetchHospitalDetail(
    int hospitalId, {
    String? accessToken,
  }) async {
    final body = await _apiClient.get(
      ApiEndpoints.hospitalDetail(hospitalId),
      headers: accessToken == null || accessToken.isEmpty
          ? null
          : ApiClient.bearerHeaders(accessToken),
    );

    final data = body['data'] as Map<String, dynamic>;

    return HospitalDetailDto.fromJson(data);
  }

  static Future<HospitalMapDto> fetchHospitalMap({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    required int zoomLevel,
    int? equipId,
  }) async {
    final queryParameters = <String, dynamic>{
      'swLat': swLat,
      'swLng': swLng,
      'neLat': neLat,
      'neLng': neLng,
      'zoomLevel': zoomLevel,
    };

    if (equipId != null) {
      queryParameters['equipId'] = equipId;
    }

    final body = await _apiClient.get(
      ApiEndpoints.hospitalMap,
      queryParameters: queryParameters,
    );

    final data = body['data'] as Map<String, dynamic>;

    return HospitalMapDto.fromJson(data);
  }
}
