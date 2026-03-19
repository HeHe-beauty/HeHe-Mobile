import 'dart:convert';
import 'dart:io';

class NaverReverseGeocode {
  static const String _clientId = String.fromEnvironment(
    'NAVER_MAP_CLIENT_ID',
    defaultValue: '',
  );
  static const String _clientSecret = String.fromEnvironment(
    'NAVER_MAP_CLIENT_SECRET',
    defaultValue: '',
  );

  static bool get isConfigured =>
      _clientId.isNotEmpty && _clientSecret.isNotEmpty;

  static Future<String?> resolveRegionLabel({
    required double latitude,
    required double longitude,
  }) async {
    if (!isConfigured) {
      print('NaverReverseGeocode is not configured.');
      return null;
    }

    final client = HttpClient();

    try {
      final uri = Uri.parse(
        'https://naveropenapi.apigw.gov-ntruss.com/map-reversegeocode/v2/gc'
            '?coords=$longitude,$latitude'
            '&sourcecrs=epsg:4326'
            '&orders=admcode,legalcode'
            '&output=json',
      );

      final request = await client.getUrl(uri);
      request.headers.set('X-NCP-APIGW-API-KEY-ID', _clientId);
      request.headers.set('X-NCP-APIGW-API-KEY', _clientSecret);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      print('reverse geocode status: ${response.statusCode}');
      print('reverse geocode body: $body');

      if (response.statusCode != HttpStatus.ok) {
        return null;
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;

      final results = decoded['results'];
      if (results is! List || results.isEmpty) return null;

      for (final item in results) {
        if (item is! Map<String, dynamic>) continue;

        final region = item['region'];
        if (region is! Map<String, dynamic>) continue;

        final area1 = _extractAreaName(region['area1']);
        final area2 = _extractAreaName(region['area2']);
        final area3 = _extractAreaName(region['area3']);
        final area4 = _extractAreaName(region['area4']);

        if (area3 != null && area3.isNotEmpty) {
          return area3;
        }

        if (area4 != null && area4.isNotEmpty) {
          if (area2 != null && area2.isNotEmpty) {
            return '$area2 $area4';
          }
          return area4;
        }

        if (area2 != null && area2.isNotEmpty) {
          return area2;
        }

        if (area1 != null && area1.isNotEmpty) {
          return area1;
        }
      }
    } catch (e, st) {
      print('reverse geocode error: $e');
      print(st);
      return null;
    } finally {
      client.close(force: true);
    }

    return null;
  }

  static String? _extractAreaName(dynamic area) {
    if (area is! Map<String, dynamic>) return null;
    final name = area['name'];
    if (name is! String || name.trim().isEmpty) return null;
    return name.trim();
  }
}
