import '../../dtos/common/bookmark/bookmark_api.dart';
import '../../dtos/common/bookmark/bookmark_dto.dart';

class BookmarkRepository {
  static Future<List<BookmarkDto>> getBookmarks({required String accessToken}) {
    return BookmarkApi.fetchBookmarks(accessToken: accessToken);
  }

  static Future<void> addBookmark({
    required String accessToken,
    required int hospitalId,
  }) {
    return BookmarkApi.createBookmark(
      accessToken: accessToken,
      hospitalId: hospitalId,
    );
  }

  static Future<void> removeBookmark({
    required String accessToken,
    required int hospitalId,
  }) {
    return BookmarkApi.deleteBookmark(
      accessToken: accessToken,
      hospitalId: hospitalId,
    );
  }
}
