import '../../dtos/common/article/article_api.dart';
import '../../dtos/common/article/article_detail_dto.dart';
import '../../dtos/common/article/article_dto.dart';

class ArticleRepository {
  static List<ArticleDto>? _cache;
  static final Map<int, ArticleDetailDto> _detailCache = {};

  static Future<List<ArticleDto>> getArticles() async {
    if (_cache != null) {
      return _cache!;
    }

    _cache = await ArticleApi.fetchArticleList();
    return _cache!;
  }

  static Future<ArticleDetailDto> getArticleDetail(int articleId) async {
    if (_detailCache.containsKey(articleId)) {
      return _detailCache[articleId]!;
    }

    final detail = await ArticleApi.fetchArticleDetail(articleId);
    _detailCache[articleId] = detail;
    return detail;
  }

  static void clearCache() {
    _cache = null;
    _detailCache.clear();
  }
}
