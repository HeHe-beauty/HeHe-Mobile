import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'bookmark_dto.dart';

class BookmarkApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<List<BookmarkDto>> fetchBookmarks({
    required String accessToken,
  }) async {
    final body = await _apiClient.get(
      ApiEndpoints.bookmarks,
      headers: ApiClient.bearerHeaders(accessToken),
    );

    ApiClient.requireSuccess(body, failureMessage: '찜한 병원 목록 조회 실패');

    final data = ApiClient.requireDataList(body);
    return data
        .map(
          (bookmark) =>
              BookmarkDto.fromJson(ApiClient.requireJsonMap(bookmark)),
        )
        .toList();
  }

  static Future<void> createBookmark({
    required String accessToken,
    required int hospitalId,
  }) async {
    final body = await _apiClient.post(
      ApiEndpoints.bookmark(hospitalId),
      headers: ApiClient.bearerHeaders(accessToken),
    );

    ApiClient.requireSuccess(body, failureMessage: '찜하기 추가 실패');
  }

  static Future<void> deleteBookmark({
    required String accessToken,
    required int hospitalId,
  }) async {
    final body = await _apiClient.delete(
      ApiEndpoints.bookmark(hospitalId),
      headers: ApiClient.bearerHeaders(accessToken),
    );

    ApiClient.requireSuccess(body, failureMessage: '찜하기 삭제 실패');
  }
}
