import '../models/subway_station.dart';

List<SubwayStation> searchSubwayStations(
  List<SubwayStation> stations,
  String query, {
  int limit = 8,
}) {
  final normalizedQuery = SubwayStation.normalize(query);
  if (normalizedQuery.isEmpty) {
    return const [];
  }

  final ranked = <({SubwayStation station, int score})>[];

  for (final station in stations) {
    final score = station.matchScoreFor(normalizedQuery);
    if (score == null) continue;
    ranked.add((station: station, score: score));
  }

  ranked.sort((a, b) {
    final scoreCompare = a.score.compareTo(b.score);
    if (scoreCompare != 0) {
      return scoreCompare;
    }

    return a.station.name.compareTo(b.station.name);
  });

  return ranked.take(limit).map((entry) => entry.station).toList();
}
