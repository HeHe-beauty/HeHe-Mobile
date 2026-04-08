import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class ServerTimeApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<Map<String, dynamic>> fetchServerTime() async {
    return _apiClient.get(ApiEndpoints.serverTime);
  }
}