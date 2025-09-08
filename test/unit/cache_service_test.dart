import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:memoria_viva_nicaragua/data/infrastructure/services/cache_service_impl.dart';
import 'package:memoria_viva_nicaragua/domain/services/i_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheServiceImpl', () {
    late ICacheService cache;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      cache = CacheServiceImpl(prefs);
      cache.setMaxEntries(3);
    });

    test('set/get con TTL', () async {
      await cache.set('k1', 'v1', ttlSeconds: 1);
      expect(await cache.get<String>('k1'), 'v1');
    });

    test('expira por TTL', () async {
      await cache.set('k2', 'v2', ttlSeconds: 0);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(await cache.get<String>('k2'), isNull);
    });

    test('LRU eviction', () async {
      await cache.set('a', '1');
      await Future.delayed(const Duration(milliseconds: 1));
      await cache.set('b', '2');
      await Future.delayed(const Duration(milliseconds: 1));
      await cache.set('c', '3');
      await cache.get('a'); // toca 'a'
      await Future.delayed(const Duration(milliseconds: 1));
      await cache.set('d', '4'); // debería expulsar 'b' (la menos usada recientemente)
      expect(await cache.get<String>('b'), isNull);
      expect(await cache.get<String>('a'), '1');
    });

    test('invalidateByTag', () async {
      await cache.set('x', '1', tag: 't');
      await cache.set('y', '2', tag: 't');
      final removed = await cache.invalidateByTag('t');
      expect(removed, 2);
      expect(await cache.get('x'), isNull);
      expect(await cache.get('y'), isNull);
    });
  });
}


