import '../../core/cache/timed_memory_cache.dart';
import '../../dtos/common/equipment/equip_api.dart';
import '../../dtos/common/equipment/equip_dto.dart';

class EquipRepository {
  static const _cacheTtl = Duration(minutes: 15);
  static final _equipsCache = TimedMemoryCache<String, List<EquipDto>>(
    ttl: _cacheTtl,
  );
  static final _detailCache = TimedMemoryCache<int, EquipDto>(ttl: _cacheTtl);

  static Future<List<EquipDto>> getEquips() {
    return _equipsCache.get('all', fetch: EquipApi.fetchEquipList);
  }

  static Future<EquipDto> getEquipDetail(int equipId) {
    return _detailCache.get(
      equipId,
      fetch: () => EquipApi.fetchEquipDetail(equipId),
    );
  }

  static void clearCache() {
    _equipsCache.clear();
    _detailCache.clear();
  }
}
