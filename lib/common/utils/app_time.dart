import 'server_time_api.dart';

class AppTime {
  static DateTime? _serverBaseTimeKst;
  static DateTime? _deviceTimeAtSync;

  static bool get isInitialized =>
      _serverBaseTimeKst != null && _deviceTimeAtSync != null;

  static Future<void> initialize() async {
    final response = await ServerTimeApi.fetchServerTime();
    final data = response['data'] as Map<String, dynamic>;
    final datetime = data['datetime'] as String;

    final serverUtc = _parseUtcDateTime(datetime);
    final serverKst = serverUtc.add(const Duration(hours: 9));

    _serverBaseTimeKst = serverKst;
    _deviceTimeAtSync = DateTime.now();
  }

  static DateTime now() {
    if (!isInitialized) {
      return DateTime.now();
    }

    final elapsed = DateTime.now().difference(_deviceTimeAtSync!);
    return _serverBaseTimeKst!.add(elapsed);
  }

  static DateTime _parseUtcDateTime(String value) {
    final normalized = value.replaceFirst(' ', 'T');
    return DateTime.parse('${normalized}Z');
  }
}