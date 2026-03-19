import 'place_item.dart';

class PlaceClusterNode {
  final String id;
  final double latitude;
  final double longitude;
  final List<PlaceItem> places;

  const PlaceClusterNode({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.places,
  });

  factory PlaceClusterNode.single(PlaceItem place) {
    return PlaceClusterNode(
      id: place.id,
      latitude: place.latitude,
      longitude: place.longitude,
      places: [place],
    );
  }

  factory PlaceClusterNode.cluster({
    required String id,
    required double latitude,
    required double longitude,
    required List<PlaceItem> places,
  }) {
    return PlaceClusterNode(
      id: id,
      latitude: latitude,
      longitude: longitude,
      places: places,
    );
  }

  bool get isCluster => places.length > 1;
  int get count => places.length;
}
