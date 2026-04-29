import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'server_time_api.dart';

class AppTime {
  static const _storage = FlutterSecureStorage();
  static const _serverBaseTimeKstKey = 'appTime.serverBaseTimeKst';
  static const _deviceTimeAtSyncKey = 'appTime.deviceTimeAtSync';
  static const _cacheTtl = Duration(hours: 1);

  static DateTime? _serverBaseTimeKst;
  static DateTime? _deviceTimeAtSync;

  static bool get isInitialized =>
      _serverBaseTimeKst != null && _deviceTimeAtSync != null;

  static Future<void> initialize() async {
    await _restoreCachedTime();
    if (_hasFreshCache) return;

    final response = await ServerTimeApi.fetchServerTime();

    final data = response['data'] as Map<String, dynamic>;
    final datetime = data['datetime'] as String;

    final serverUtc = _parseUtcDateTime(datetime);
    final serverKst = serverUtc.add(const Duration(hours: 9));
    final syncedAt = DateTime.now().toUtc();

    _serverBaseTimeKst = serverKst;
    _deviceTimeAtSync = syncedAt;

    await _storage.write(
      key: _serverBaseTimeKstKey,
      value: serverKst.toIso8601String(),
    );
    await _storage.write(
      key: _deviceTimeAtSyncKey,
      value: syncedAt.toIso8601String(),
    );
  }

  static DateTime now() {
    if (!isInitialized) {
      return DateTime.now().toUtc().add(const Duration(hours: 9));
    }

    final elapsed = DateTime.now().toUtc().difference(_deviceTimeAtSync!);

    return _serverBaseTimeKst!.add(elapsed);
  }

  static DateTime _parseUtcDateTime(String value) {
    final normalized = value.replaceFirst(' ', 'T');
    return DateTime.parse('${normalized}Z');
  }

  static Future<void> _restoreCachedTime() async {
    if (isInitialized) return;

    final cachedServerBaseTime = await _storage.read(
      key: _serverBaseTimeKstKey,
    );
    final cachedDeviceSyncTime = await _storage.read(key: _deviceTimeAtSyncKey);
    if (cachedServerBaseTime == null || cachedDeviceSyncTime == null) return;

    final parsedServerBaseTime = DateTime.tryParse(cachedServerBaseTime);
    final parsedDeviceSyncTime = DateTime.tryParse(cachedDeviceSyncTime);
    if (parsedServerBaseTime == null || parsedDeviceSyncTime == null) return;

    _serverBaseTimeKst = parsedServerBaseTime;
    _deviceTimeAtSync = parsedDeviceSyncTime.toUtc();
  }

  static bool get _hasFreshCache {
    if (!isInitialized) return false;

    final elapsed = DateTime.now().toUtc().difference(_deviceTimeAtSync!);
    return elapsed <= _cacheTtl;
  }
}
