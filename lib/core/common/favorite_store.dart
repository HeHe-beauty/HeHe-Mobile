import 'package:flutter/foundation.dart';

import '../../data/mock_place_data.dart';
import '../../models/place_item.dart';

class FavoriteStore extends ChangeNotifier {
  FavoriteStore._internal() {
    _allPlaces = MockPlaceData.buildMockHospitals();
    _favoriteIds = MockPlaceData.buildInitialFavoriteIds(_allPlaces);
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

  PlaceItem? findByHospitalId(int hospitalId) {
    final place = _findRawByHospitalId(hospitalId);
    return place == null ? null : applyFavoriteState(place);
  }

  PlaceItem applyFavoriteState(PlaceItem place) {
    final storedPlace = place.hospitalId == null
        ? null
        : _findRawByHospitalId(place.hospitalId!);

    return place.copyWith(
      isBookmarked: isFavorite(storedPlace?.id ?? place.id),
    );
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

  PlaceItem? _findRawByHospitalId(int hospitalId) {
    for (final place in _allPlaces) {
      if (place.hospitalId == hospitalId) {
        return place;
      }
    }
    return null;
  }
}
