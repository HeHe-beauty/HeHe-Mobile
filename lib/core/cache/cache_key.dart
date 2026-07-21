String authScopedCacheKey(String? accessToken) {
  if (accessToken == null || accessToken.isEmpty) return 'guest';
  return 'signed:${accessToken.hashCode}';
}
