import 'package:flutter/foundation.dart';

import '../../data/bookmark/bookmark_repository.dart';
import '../../data/hospital/hospital_repository.dart';
import '../../models/place_item.dart';
import '../../utils/place_item_mappers.dart';

class FavoriteStore extends ChangeNotifier {
  FavoriteStore._internal();

  static final FavoriteStore instance = FavoriteStore._internal();

  List<PlaceItem> _favoritePlaces = const [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<PlaceItem> get allPlaces => favoritePlaces;

  List<PlaceItem> get favoritePlaces => List.unmodifiable(_favoritePlaces);

  Future<void> loadBookmarks({required String accessToken}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final bookmarks = await BookmarkRepository.getBookmarks(
        accessToken: accessToken,
      );
      _favoritePlaces = await Future.wait(
        bookmarks.map((bookmark) async {
          final fallbackPlace = placeItemFromBookmark(bookmark);

          try {
            final detail = await HospitalRepository.getHospitalDetail(
              bookmark.hospitalId,
            );
            return placeItemFromHospitalDetail(
              detail,
              fallbackPlace: fallbackPlace,
            );
          } catch (_) {
            return fallbackPlace;
          }
        }),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _favoritePlaces = const [];
    _isLoading = false;
    notifyListeners();
  }

  bool isFavorite(String placeId) {
    return _favoritePlaces.any((place) => place.id == placeId);
  }

  bool containsPlace(String placeId) {
    return isFavorite(placeId);
  }

  PlaceItem? findById(String placeId) {
    final place = _findById(placeId);
    return place == null ? null : applyFavoriteState(place);
  }

  PlaceItem? findByHospitalId(int hospitalId) {
    final place = _findByHospitalId(hospitalId);
    return place == null ? null : applyFavoriteState(place);
  }

  PlaceItem applyFavoriteState(PlaceItem place) {
    return place.copyWith(
      isBookmarked:
          isFavorite(place.id) ||
          (place.hospitalId != null &&
              _findByHospitalId(place.hospitalId!) != null),
    );
  }

  List<PlaceItem> applyFavoriteStateToAll(Iterable<PlaceItem> places) {
    return places.map(applyFavoriteState).toList(growable: false);
  }

  Future<void> setBookmark({
    required String accessToken,
    required PlaceItem place,
    required bool enabled,
  }) async {
    final hospitalId = place.hospitalId ?? _findById(place.id)?.hospitalId;
    if (hospitalId == null) {
      throw ArgumentError('찜하기를 변경할 병원 정보가 없습니다.');
    }

    if (enabled) {
      await BookmarkRepository.addBookmark(
        accessToken: accessToken,
        hospitalId: hospitalId,
      );
      _addLocalFavorite(place.copyWith(hospitalId: hospitalId));
      return;
    }

    await BookmarkRepository.removeBookmark(
      accessToken: accessToken,
      hospitalId: hospitalId,
    );
    _removeLocalFavorite(hospitalId: hospitalId, placeId: place.id);
  }

  void _addLocalFavorite(PlaceItem place) {
    if (isFavorite(place.id)) return;

    _favoritePlaces = [place.copyWith(isBookmarked: true), ..._favoritePlaces];
    notifyListeners();
  }

  void _removeLocalFavorite({
    required int hospitalId,
    required String placeId,
  }) {
    _favoritePlaces = _favoritePlaces
        .where(
          (favoritePlace) =>
              favoritePlace.id != placeId &&
              favoritePlace.hospitalId != hospitalId,
        )
        .toList(growable: false);

    notifyListeners();
  }

  PlaceItem? _findById(String placeId) {
    for (final place in _favoritePlaces) {
      if (place.id == placeId) {
        return place;
      }
    }
    return null;
  }

  PlaceItem? _findByHospitalId(int hospitalId) {
    for (final place in _favoritePlaces) {
      if (place.hospitalId == hospitalId) {
        return place;
      }
    }
    return null;
  }
}
