import 'package:geolocator/geolocator.dart';

import '../models/place_item.dart';

String formatPlaceDistanceLabel({
  required PlaceItem place,
  required double? currentLatitude,
  required double? currentLongitude,
}) {
  if (currentLatitude == null ||
      currentLongitude == null ||
      !_hasUsablePlaceCoordinate(place)) {
    return '거리 확인 불가';
  }

  final distanceMeters = Geolocator.distanceBetween(
    currentLatitude,
    currentLongitude,
    place.latitude,
    place.longitude,
  );

  final distanceKm = distanceMeters / 1000;
  final formattedDistance = distanceKm.toStringAsFixed(1);

  return '여기서 ${formattedDistance}km';
}

bool _hasUsablePlaceCoordinate(PlaceItem place) {
  return place.latitude != 0 || place.longitude != 0;
}
