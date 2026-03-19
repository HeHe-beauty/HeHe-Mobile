import '../models/place_cluster_node.dart';
import '../models/place_item.dart';

List<PlaceClusterNode> buildPlaceClusterNodes(
  List<PlaceItem> places,
  double zoom,
) {
  final cellSize = cellSizeForZoom(zoom);

  if (cellSize <= 0) {
    return places.map(PlaceClusterNode.single).toList();
  }

  final grouped = <String, List<PlaceItem>>{};

  for (final place in places) {
    final latKey = (place.latitude / cellSize).floor();
    final lngKey = (place.longitude / cellSize).floor();
    final key = '$latKey:$lngKey';

    grouped.putIfAbsent(key, () => []).add(place);
  }

  return grouped.entries.map((entry) {
    final groupPlaces = entry.value;

    if (groupPlaces.length == 1) {
      return PlaceClusterNode.single(groupPlaces.first);
    }

    final avgLat =
        groupPlaces.map((e) => e.latitude).reduce((a, b) => a + b) /
        groupPlaces.length;
    final avgLng =
        groupPlaces.map((e) => e.longitude).reduce((a, b) => a + b) /
        groupPlaces.length;

    return PlaceClusterNode.cluster(
      id: 'cluster_${entry.key}_${groupPlaces.length}',
      latitude: avgLat,
      longitude: avgLng,
      places: groupPlaces,
    );
  }).toList();
}

double cellSizeForZoom(double zoom) {
  if (zoom <= 10) return 0.040;
  if (zoom <= 11) return 0.030;
  if (zoom <= 12) return 0.020;
  if (zoom <= 13) return 0.012;
  if (zoom <= 14) return 0.008;
  if (zoom <= 15) return 0.004;
  if (zoom <= 16) return 0.002;
  return 0;
}
