import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../models/place_item.dart';

class FavoriteStore extends ChangeNotifier {
  FavoriteStore._internal() {
    _allPlaces = _buildMockHospitals();
    _favoriteIds = _buildInitialFavoriteIds(_allPlaces);
  }

  static final FavoriteStore instance = FavoriteStore._internal();

  late final List<PlaceItem> _allPlaces;
  late final Set<String> _favoriteIds;

  List<PlaceItem> get allPlaces => applyFavoriteStateToAll(_allPlaces);

  List<PlaceItem> get favoritePlaces => _allPlaces
      .where((place) => _favoriteIds.contains(place.id))
      .map(applyFavoriteState)
      .toList(growable: false);

  bool isFavorite(String placeId) => _favoriteIds.contains(placeId);

  bool containsPlace(String placeId) {
    return _allPlaces.any((place) => place.id == placeId);
  }

  PlaceItem? findById(String placeId) {
    for (final place in _allPlaces) {
      if (place.id == placeId) {
        return applyFavoriteState(place);
      }
    }
    return null;
  }

  PlaceItem applyFavoriteState(PlaceItem place) {
    return place.copyWith(isBookmarked: isFavorite(place.id));
  }

  List<PlaceItem> applyFavoriteStateToAll(Iterable<PlaceItem> places) {
    return places.map(applyFavoriteState).toList(growable: false);
  }

  void toggleFavorite(String placeId) {
    if (!containsPlace(placeId)) return;

    if (_favoriteIds.contains(placeId)) {
      _favoriteIds.remove(placeId);
    } else {
      _favoriteIds.add(placeId);
    }

    notifyListeners();
  }

  static List<PlaceItem> _buildMockHospitals() {
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

  static Set<String> _buildInitialFavoriteIds(List<PlaceItem> places) {
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
}
