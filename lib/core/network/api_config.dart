class ApiConfig {
  static const String scheme = 'http';
  static const String host = '13.209.32.82:8080/api';

  static Uri uri(String path, [Map<String, dynamic>? queryParameters]) {
    return Uri(
      scheme: scheme,
      host: host,
      path: path,
      queryParameters: queryParameters?.map(
            (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }
}