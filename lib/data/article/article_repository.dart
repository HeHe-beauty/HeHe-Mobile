import '../../core/cache/timed_memory_cache.dart';
import '../../dtos/common/article/article_api.dart';
import '../../dtos/common/article/article_detail_dto.dart';
import '../../dtos/common/article/article_dto.dart';

class ArticleRepository {
  static const _cacheTtl = Duration(minutes: 5);
  static final _articlesCache = TimedMemoryCache<String, List<ArticleDto>>(
    ttl: _cacheTtl,
  );
  static final _detailCache = TimedMemoryCache<int, ArticleDetailDto>(
    ttl: _cacheTtl,
  );

  static Future<List<ArticleDto>> getArticles() {
    return _articlesCache.get('all', fetch: ArticleApi.fetchArticleList);
  }

  static Future<ArticleDetailDto> getArticleDetail(int articleId) {
    return _detailCache.get(
      articleId,
      fetch: () => ArticleApi.fetchArticleDetail(articleId),
    );
  }

  static void clearCache() {
    _articlesCache.clear();
    _detailCache.clear();
  }
}
