import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hehe/core/cache/timed_memory_cache.dart';

void main() {
  group('TimedMemoryCache', () {
    test('deduplicates concurrent requests for the same key', () async {
      final cache = TimedMemoryCache<String, int>(
        ttl: const Duration(minutes: 1),
      );
      final completer = Completer<int>();
      var fetchCount = 0;

      Future<int> fetch() {
        fetchCount += 1;
        return completer.future;
      }

      final first = cache.get('same', fetch: fetch);
      final second = cache.get('same', fetch: fetch);
      completer.complete(7);

      expect(await Future.wait([first, second]), [7, 7]);
      expect(fetchCount, 1);
    });

    test('does not repopulate the cache after clear', () async {
      final cache = TimedMemoryCache<String, int>(
        ttl: const Duration(minutes: 1),
      );
      final firstRequest = Completer<int>();

      final pending = cache.get('key', fetch: () => firstRequest.future);
      cache.clear();
      firstRequest.complete(1);
      expect(await pending, 1);

      var refetched = false;
      final value = await cache.get(
        'key',
        fetch: () async {
          refetched = true;
          return 2;
        },
      );

      expect(refetched, isTrue);
      expect(value, 2);
    });
  });
}
