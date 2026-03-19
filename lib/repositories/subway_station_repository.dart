import '../data/subway_station_loader.dart';
import '../models/subway_station.dart';
import '../utils/subway_station_search.dart';

class SubwayStationRepository {
  List<SubwayStation>? _cachedStations;

  Future<List<SubwayStation>> loadStations() async {
    final cachedStations = _cachedStations;
    if (cachedStations != null) {
      return cachedStations;
    }

    final stations = await loadSeoulStations();
    _cachedStations = stations;
    return stations;
  }

  Future<List<SubwayStation>> searchStations(
    String query, {
    int limit = 8,
  }) async {
    final normalizedQuery = SubwayStation.normalize(query);
    if (normalizedQuery.isEmpty) return const [];

    final stations = await loadStations();
    return searchSubwayStations(stations, normalizedQuery, limit: limit);
  }

  Future<SubwayStation?> findBestMatch(String query) async {
    final results = await searchStations(query, limit: 1);
    if (results.isEmpty) return null;
    return results.first;
  }
}
