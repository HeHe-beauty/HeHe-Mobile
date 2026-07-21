import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'equip_dto.dart';

class EquipApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<List<EquipDto>> fetchEquipList() async {
    final body = await _apiClient.get(ApiEndpoints.equipList);

    final data = ApiClient.requireDataList(body);

    final list = data
        .map((item) => EquipDto.fromJson(ApiClient.requireJsonMap(item)))
        .toList();

    // displayOrder 기준 정렬
    list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return list;
  }

  static Future<EquipDto> fetchEquipDetail(int equipId) async {
    final body = await _apiClient.get(ApiEndpoints.equipDetail(equipId));

    final data = ApiClient.requireDataMap(body);

    return EquipDto.fromJson(data);
  }
}
