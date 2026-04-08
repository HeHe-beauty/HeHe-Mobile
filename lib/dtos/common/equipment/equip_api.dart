import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'equip_dto.dart';

class EquipApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<List<EquipDto>> fetchEquipList() async {
    final body = await _apiClient.get(ApiEndpoints.equipList);

    final data = body['data'] as List<dynamic>;

    final list = data
        .map((e) => EquipDto.fromJson(e as Map<String, dynamic>))
        .toList();

    // displayOrder 기준 정렬
    list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return list;
  }
}