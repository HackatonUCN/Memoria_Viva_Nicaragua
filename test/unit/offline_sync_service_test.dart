import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:memoria_viva_nicaragua/domain/services/i_cache_service.dart';
import 'package:memoria_viva_nicaragua/data/infrastructure/services/cache_service_impl.dart';
import 'package:memoria_viva_nicaragua/data/infrastructure/services/offline_sync_service_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineSyncServiceImpl', () {
    late FirebaseFirestore firestore;
    late ICacheService cache;
    late OfflineSyncServiceImpl service;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      cache = CacheServiceImpl(prefs);
      service = OfflineSyncServiceImpl(firestore, cache);
    });

    test('inicializar y activar modo offline no lanza', () async {
      await service.inicializar();
      expect(service.estaEnModoOffline(), isA<bool>());
    });

    test('configurar y obtener estado de sincronización', () async {
      await service.configurarContenidoASincronizar(['relatos', 'categorias']);
      final estado = await service.obtenerEstadoSincronizacion();
      expect(estado, contains('online'));
    });
  });
}


