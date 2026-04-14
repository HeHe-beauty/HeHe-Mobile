import '../../dtos/common/hospital/hospital_api.dart';
import '../../dtos/common/hospital/hospital_detail_dto.dart';
import '../../dtos/common/hospital/hospital_dto.dart';
import '../../dtos/common/hospital/hospital_map_dto.dart';

class HospitalRepository {
  static final Map<String, List<HospitalDto>> _cache = {};
  static final Map<int, HospitalDetailDto> _detailCache = {};

  static Future<List<HospitalDto>> getHospitals({
    required double lat,
    required double lng,
    required int precision,
    int? equipId,
  }) async {
    final cacheKey = '$lat:$lng:$precision:${equipId ?? 'all'}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final hospitals = await HospitalApi.fetchHospitalList(
      lat: lat,
      lng: lng,
      precision: precision,
      equipId: equipId,
    );
    _cache[cacheKey] = hospitals;
    return hospitals;
  }

  static Future<HospitalDetailDto> getHospitalDetail(int hospitalId) async {
    if (_detailCache.containsKey(hospitalId)) {
      return _detailCache[hospitalId]!;
    }

    final detail = await HospitalApi.fetchHospitalDetail(hospitalId);
    _detailCache[hospitalId] = detail;
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
