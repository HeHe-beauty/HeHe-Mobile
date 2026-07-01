import 'package:flutter_test/flutter_test.dart';
import 'package:hehe/dtos/common/article/article_detail_dto.dart';

void main() {
  test('parses the complete article detail payload data', () {
    final dto = ArticleDetailDto.fromJson({
      'articleId': 1,
      'title': '레이저 제모 완벽 가이드',
      'subTitle': '시작 전 알아야 할 것들',
      'thumbnailUrl': 'https://example.com/thumb.jpg',
      'content': '본문',
      'tags': [' 제모 ', '피부관리'],
      'createdAt': '2025-01-01 12:00:00',
      'updatedAt': '2025-06-01 09:00:00',
    });

    expect(dto.articleId, 1);
    expect(dto.subTitle, '시작 전 알아야 할 것들');
    expect(dto.thumbnailUrl, 'https://example.com/thumb.jpg');
    expect(dto.tags, ['제모', '피부관리']);
    expect(dto.createdAt, '2025-01-01 12:00:00');
    expect(dto.updatedAt, '2025-06-01 09:00:00');
  });

  test('tolerates optional empty article fields', () {
    final dto = ArticleDetailDto.fromJson({
      'articleId': 2,
      'title': '제목',
      'content': null,
      'tags': null,
    });

    expect(dto.content, isEmpty);
    expect(dto.tags, isEmpty);
    expect(dto.thumbnailUrl, isNull);
  });
}
