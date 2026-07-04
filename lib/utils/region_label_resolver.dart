import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';

import '../core/cache/timed_memory_cache.dart';

class RegionLabelResolver {
  const RegionLabelResolver._();

  static final Geocoding _geocoding = Geocoding(
    locale: const Locale('ko', 'KR'),
  );
  static final TimedMemoryCache<String, String?> _cache = TimedMemoryCache(
    ttl: const Duration(days: 1),
  );

  static Future<String?> resolve({
    required double latitude,
    required double longitude,
  }) {
    final cacheKey =
        '${latitude.toStringAsFixed(3)}:${longitude.toStringAsFixed(3)}';

    return _cache.get(
      cacheKey,
      fetch: () => _resolveFromPlatform(latitude, longitude),
    );
  }

  static Future<String?> _resolveFromPlatform(
    double latitude,
    double longitude,
  ) async {
    try {
      if (!await _geocoding.isPresent()) return null;

      final placemarks = await _geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isEmpty) return null;

      return formatPlacemark(placemarks.first);
    } catch (_) {
      return null;
    }
  }

  static String? formatPlacemark(Placemark placemark) {
    final district = _firstMatching([
      placemark.subAdministrativeArea,
      placemark.locality,
      placemark.subLocality,
    ], RegExp(r'(구|군)$'));
    final neighborhood = _firstMatching([
      placemark.subLocality,
      placemark.locality,
      placemark.thoroughfare,
    ], RegExp(r'(동|읍|면|가)$'));

    final preciseParts = <String>{?district, ?neighborhood};
    if (preciseParts.isNotEmpty) return preciseParts.join(' ');

    final fallbackParts = <String>{};
    for (final value in [
      placemark.subLocality,
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
    ]) {
      final normalized = _normalize(value);
      if (normalized != null) fallbackParts.add(normalized);
      if (fallbackParts.length == 2) break;
    }

    return fallbackParts.isEmpty ? null : fallbackParts.join(' ');
  }

  static String? _firstMatching(Iterable<String?> values, RegExp pattern) {
    for (final value in values) {
      final normalized = _normalize(value);
      if (normalized != null && pattern.hasMatch(normalized)) {
        return normalized;
      }
    }
    return null;
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
