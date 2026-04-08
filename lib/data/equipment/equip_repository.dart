import '../../dtos/common/equipment/equip_api.dart';
import '../../dtos/common/equipment/equip_dto.dart';

class EquipRepository {
  static List<EquipDto>? _cache;

  static Future<List<EquipDto>> getEquips() async {
    if (_cache != null) {
      return _cache!;
    }

    _cache = await EquipApi.fetchEquipList();
    return _cache!;
  }

  static void clearCache() {
    _cache = null;
  }
}