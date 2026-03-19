class SubwayStation {
  final String id;
  final String name;
  final List<String> aliases;
  final List<String> lines;
  final double latitude;
  final double longitude;

  const SubwayStation({
    required this.id,
    required this.name,
    required this.aliases,
    required this.lines,
    required this.latitude,
    required this.longitude,
  });

  factory SubwayStation.fromJson(Map<String, dynamic> json) {
    return SubwayStation(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases: (json['aliases'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(growable: false),
      lines: (json['lines'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(growable: false),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  int? matchScoreFor(String query) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return null;

    var bestScore = _scoreForTerm(normalize(name), normalizedQuery);

    for (final alias in aliases) {
      final aliasScore = _scoreForTerm(normalize(alias), normalizedQuery);
      if (aliasScore == null) continue;
      bestScore = bestScore == null || aliasScore < bestScore
          ? aliasScore
          : bestScore;
    }

    return bestScore;
  }

  static String normalize(String value) {
    final compact = value.replaceAll(' ', '');
    if (compact.endsWith('역')) {
      return compact.substring(0, compact.length - 1);
    }
    return compact;
  }

  static int? _scoreForTerm(String term, String query) {
    if (term == query) {
      return 0;
    }

    if (term.startsWith(query)) {
      return 1;
    }

    if (term.contains(query)) {
      return 2;
    }

    return null;
  }
}
