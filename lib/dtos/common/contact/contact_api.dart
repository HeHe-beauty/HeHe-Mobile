import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'contact_create_request_dto.dart';
import 'contact_dto.dart';

class ContactApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<List<ContactDto>> fetchContacts({
    required String accessToken,
  }) async {
    final body = await _apiClient.get(
      ApiEndpoints.contacts,
      headers: ApiClient.bearerHeaders(accessToken),
    );

    if (body['success'] != true) {
      throw Exception('문의 내역 조회 실패');
    }

    final data = body['data'] as List<dynamic>;
    return data
        .map((contact) => ContactDto.fromJson(contact as Map<String, dynamic>))
        .toList();
  }

  static Future<void> createContact({
    required String accessToken,
    required ContactCreateRequestDto request,
  }) async {
    final body = await _apiClient.post(
      ApiEndpoints.contacts,
      body: request.toJson(),
      headers: ApiClient.bearerHeaders(accessToken),
    );

    if (body['success'] != true) {
      throw Exception('문의 내역 등록 실패');
    }
  }

  static Future<void> deleteContact({
    required String accessToken,
    required int contactId,
  }) async {
    final body = await _apiClient.delete(
      ApiEndpoints.contact(contactId),
      headers: ApiClient.bearerHeaders(accessToken),
    );

    if (body['success'] != true) {
      throw Exception('문의 내역 삭제 실패');
    }
  }
}
