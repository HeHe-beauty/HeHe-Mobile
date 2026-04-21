class TimedMemoryCache<K, V> {
  final Duration ttl;
  final Map<K, V> _values = {};
  final Map<K, DateTime> _fetchedAt = {};
  final Map<K, Future<V>> _inFlight = {};

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
    if (inFlight != null) {
      return inFlight;
    }

    final request = fetch()
        .then((value) {
          _values[key] = value;
          _fetchedAt[key] = DateTime.now();
          return value;
        })
        .whenComplete(() {
          _inFlight.remove(key);
        });

    _inFlight[key] = request;
    return request;
  }

  void clear() {
    _values.clear();
    _fetchedAt.clear();
    _inFlight.clear();
  }
}
