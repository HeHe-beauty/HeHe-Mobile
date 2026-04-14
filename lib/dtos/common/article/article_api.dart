import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'article_detail_dto.dart';
import 'article_dto.dart';

class ArticleApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<List<ArticleDto>> fetchArticleList() async {
    final body = await _apiClient.get(ApiEndpoints.articleList);

    final data = body['data'] as List<dynamic>;

    return data
        .map((e) => ArticleDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ArticleDetailDto> fetchArticleDetail(int articleId) async {
    final body = await _apiClient.get(ApiEndpoints.articleDetail(articleId));

    final data = body['data'] as Map<String, dynamic>;

    return ArticleDetailDto.fromJson(data);
  }
}
