import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'article_detail_dto.dart';
import 'article_dto.dart';

class ArticleApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<List<ArticleDto>> fetchArticleList() async {
    final body = await _apiClient.get(ApiEndpoints.articleList);

    final data = ApiClient.requireDataList(body);

    return data
        .map((item) => ArticleDto.fromJson(ApiClient.requireJsonMap(item)))
        .toList();
  }

  static Future<ArticleDetailDto> fetchArticleDetail(int articleId) async {
    final body = await _apiClient.get(ApiEndpoints.articleDetail(articleId));

    final data = ApiClient.requireDataMap(body);

    return ArticleDetailDto.fromJson(data);
  }
}
