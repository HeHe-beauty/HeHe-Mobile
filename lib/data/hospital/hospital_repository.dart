import '../../dtos/common/hospital/hospital_api.dart';
import '../../dtos/common/hospital/hospital_detail_dto.dart';
import '../../dtos/common/hospital/hospital_dto.dart';
import '../../dtos/common/hospital/hospital_map_dto.dart';

class HospitalRepository {
  static final Map<String, List<HospitalDto>> _cache = {};
  static final Map<String, HospitalDetailDto> _detailCache = {};

  static Future<List<HospitalDto>> getHospitals({
    required double lat,
    required double lng,
    required int precision,
    int? equipId,
    String? accessToken,
  }) async {
    final cacheKey =
        '$lat:$lng:$precision:${equipId ?? 'all'}:${accessToken ?? 'guest'}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final hospitals = await HospitalApi.fetchHospitalList(
      lat: lat,
      lng: lng,
      precision: precision,
      equipId: equipId,
      accessToken: accessToken,
    );
    _cache[cacheKey] = hospitals;
    return hospitals;
  }

  static Future<HospitalDetailDto> getHospitalDetail(
    int hospitalId, {
    String? accessToken,
  }) async {
    final cacheKey = '$hospitalId:${accessToken ?? 'guest'}';
    if (_detailCache.containsKey(cacheKey)) {
      return _detailCache[cacheKey]!;
    }

    final detail = await HospitalApi.fetchHospitalDetail(
      hospitalId,
      accessToken: accessToken,
    );
    _detailCache[cacheKey] = detail;
    return detail;
  }

  static Future<HospitalMapDto> getHospitalMap({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    required int zoomLevel,
    int? equipId,
  }) {
    return HospitalApi.fetchHospitalMap(
      swLat: swLat,
      swLng: swLng,
      neLat: neLat,
      neLng: neLng,
      zoomLevel: zoomLevel,
      equipId: equipId,
    );
  }

  static void clearCache() {
    _cache.clear();
    _detailCache.clear();
  }
}
