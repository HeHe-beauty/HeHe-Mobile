import '../../core/cache/cache_key.dart';
import '../../core/cache/timed_memory_cache.dart';
import '../../dtos/common/hospital/hospital_api.dart';
import '../../dtos/common/hospital/hospital_detail_dto.dart';
import '../../dtos/common/hospital/hospital_dto.dart';
import '../../dtos/common/hospital/hospital_map_dto.dart';

class HospitalRepository {
  static const _cacheTtl = Duration(minutes: 1);
  static final _hospitalsCache = TimedMemoryCache<String, List<HospitalDto>>(
    ttl: _cacheTtl,
  );
  static final _detailCache = TimedMemoryCache<String, HospitalDetailDto>(
    ttl: _cacheTtl,
  );

  static Future<List<HospitalDto>> getHospitals({
    required double lat,
    required double lng,
    required int precision,
    int? equipId,
    String? accessToken,
  }) {
    final cacheKey =
        '$lat:$lng:$precision:${equipId ?? 'all'}:'
        '${authScopedCacheKey(accessToken)}';

    return _hospitalsCache.get(
      cacheKey,
      fetch: () => HospitalApi.fetchHospitalList(
        lat: lat,
        lng: lng,
        precision: precision,
        equipId: equipId,
        accessToken: accessToken,
      ),
    );
  }

  static Future<HospitalDetailDto> getHospitalDetail(
    int hospitalId, {
    String? accessToken,
  }) {
    final cacheKey = '$hospitalId:${authScopedCacheKey(accessToken)}';
    return _detailCache.get(
      cacheKey,
      fetch: () =>
          HospitalApi.fetchHospitalDetail(hospitalId, accessToken: accessToken),
    );
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
    _hospitalsCache.clear();
    _detailCache.clear();
  }
}
