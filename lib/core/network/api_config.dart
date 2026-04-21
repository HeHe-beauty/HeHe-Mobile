class ApiConfig {
  static const String scheme = 'https';
  static const String host = 'hehehe.kr';

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