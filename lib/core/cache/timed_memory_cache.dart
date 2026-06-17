class TimedMemoryCache<K, V> {
  final Duration ttl;
  final Map<K, V> _values = {};
  final Map<K, DateTime> _fetchedAt = {};
  final Map<K, Future<V>> _inFlight = {};
  final Map<K, Object> _inFlightTokens = {};
  int _generation = 0;

  TimedMemoryCache({required this.ttl});

  Future<V> get(
    K key, {
    required Future<V> Function() fetch,
    bool forceRefresh = false,
  }) {
    final cached = _values[key];
    final cachedAt = _fetchedAt[key];

    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < ttl) {
      return Future.value(cached);
    }

    final inFlight = _inFlight[key];
    if (!forceRefresh && inFlight != null) {
      return inFlight;
    }

    final requestGeneration = _generation;
    final requestToken = Object();
    final request = fetch()
        .then((value) {
          if (requestGeneration == _generation) {
            _values[key] = value;
            _fetchedAt[key] = DateTime.now();
          }
          return value;
        })
        .whenComplete(() {
          if (identical(_inFlightTokens[key], requestToken)) {
            _inFlight.remove(key);
            _inFlightTokens.remove(key);
          }
        });

    _inFlight[key] = request;
    _inFlightTokens[key] = requestToken;
    return request;
  }

  void clear() {
    _generation += 1;
    _values.clear();
    _fetchedAt.clear();
    _inFlight.clear();
    _inFlightTokens.clear();
  }
}
