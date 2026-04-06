import 'dart:math';

import '../models/place_item.dart';

class MockPlaceData {
  const MockPlaceData._();

  static List<PlaceItem> buildMockHospitals() {
    const baseLat = 37.4979;
    const baseLng = 127.0276;
    final random = Random(7);

    return List.generate(48, (index) {
      final latOffset = (random.nextDouble() - 0.5) * 0.014;
      final lngOffset = (random.nextDouble() - 0.5) * 0.016;

      return PlaceItem(
        id: 'hospital_$index',
        name: '테스트 병원 ${index + 1}',
        tags: index.isEven ? ['#피부', '#토닝'] : ['#레이저', '#남성시술'],
        description: '임시 데이터로 넣은 병원입니다.',
        address: '서울 강남구 테헤란로 ${101 + index}',
        isBookmarked: false,
        latitude: baseLat + latOffset,
        longitude: baseLng + lngOffset,
      );
    });
  }

  static Set<String> buildInitialFavoriteIds(List<PlaceItem> places) {
    final random = Random();
    final ids = <String>{};

    for (final place in places) {
      if (random.nextDouble() < 0.28) {
        ids.add(place.id);
      }
    }

    if (ids.isEmpty && places.isNotEmpty) {
      ids.add(places[random.nextInt(places.length)].id);
    }

    return ids;
  }

  static List<PlaceItem> recentPlaces() {
    return const [
      PlaceItem(
        id: 'recent_xx',
        name: 'XX 의원',
        tags: ['#피부', '#레이저'],
        description: '후기 많고 접근성 좋은 곳',
        address: '임시 주소 1',
        isBookmarked: true,
        latitude: 37.4979,
        longitude: 127.0276,
      ),
      PlaceItem(
        id: 'recent_yy',
        name: 'YY 클리닉',
        tags: ['#피부', '#토닝'],
        description: '상담 만족도가 높은 편',
        address: '임시 주소 2',
        isBookmarked: true,
        latitude: 37.4993,
        longitude: 127.0310,
      ),
      PlaceItem(
        id: 'recent_ab',
        name: 'AB 피부과',
        tags: ['#여드름', '#모공'],
        description: '기기 다양, 예약 편리',
        address: '임시 주소 3',
        isBookmarked: false,
        latitude: 37.4958,
        longitude: 127.0305,
      ),
    ];
  }

  static List<PlaceItem> inquiryPlaces() {
    return const [
      PlaceItem(
        id: 'inquiry_gh',
        name: 'GH 피부과',
        tags: ['#색소', '#토닝'],
        description: '설명 자세하고 빠른 예약 가능',
        address: '임시 주소 6',
        isBookmarked: false,
        latitude: 37.4966,
        longitude: 127.0249,
      ),
      PlaceItem(
        id: 'inquiry_cd',
        name: 'CD 의원',
        tags: ['#제모', '#남성시술'],
        description: '가성비 괜찮고 재방문율 높음',
        address: '임시 주소 7',
        isBookmarked: false,
        latitude: 37.5002,
        longitude: 127.0257,
      ),
    ];
  }
}
