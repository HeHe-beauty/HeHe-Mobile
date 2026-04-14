import '../../dtos/common/equipment/equip_api.dart';
import '../../dtos/common/equipment/equip_dto.dart';

class EquipRepository {
  static List<EquipDto>? _cache;
  static final Map<int, EquipDto> _detailCache = {};

  static Future<List<EquipDto>> getEquips() async {
    if (_cache != null) {
      return _cache!;
    }

    _cache = await EquipApi.fetchEquipList();
    return _cache!;
  }

  static Future<EquipDto> getEquipDetail(int equipId) async {
    if (_detailCache.containsKey(equipId)) {
      return _detailCache[equipId]!;
    }

    final detail = await EquipApi.fetchEquipDetail(equipId);
    _detailCache[equipId] = detail;
    return detail;
  }

  static void clearCache() {
    _cache = null;
    _detailCache.clear();
  }
}
