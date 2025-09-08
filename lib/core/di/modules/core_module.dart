import 'package:get_it/get_it.dart';

import '../service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../di/di_errors.dart';
import '../../../domain/services/i_cache_service.dart';
import '../../../data/infrastructure/services/cache_service_impl.dart';
import '../../../domain/services/i_offline_sync_service.dart';
import '../../../data/infrastructure/services/offline_sync_service_impl.dart';
import '../../../domain/services/i_sync_queue.dart';
import '../../../data/infrastructure/services/sync_queue_impl.dart';
import '../../../domain/services/i_connectivity_service.dart';
import '../../../data/infrastructure/services/connectivity_service_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro de dependencias core de la app.
/// Mantén este módulo para utilidades compartidas (logger, config, mappers, etc.)
class CoreModule {
  static void register(GetIt getIt, {required DIEnvironment env}) {
    // Ejemplos de registro:
    // getIt.registerLazySingleton<AppLogger>(() => AppLogger(env: env));
    // getIt.registerFactory<Mapper<UserDto, User>>(() => UserMapper());

    // SharedPreferences + CacheService
    getIt.registerSingletonAsync<SharedPreferences>(() async => await SharedPreferences.getInstance());
    getIt.registerSingletonWithDependencies<ICacheService>(
      () => CacheServiceImpl(getIt<SharedPreferences>()),
      dependsOn: [SharedPreferences],
    );

    // OfflineSyncService (requiere Firestore y Cache)
    getIt.registerSingletonWithDependencies<IOfflineSyncService>(
      () => OfflineSyncServiceImpl(FirebaseFirestore.instance, getIt<ICacheService>()),
      dependsOn: [ICacheService],
    );

    // SyncQueue persistente
    getIt.registerSingletonWithDependencies<ISyncQueue>(
      () => SyncQueueImpl(getIt<SharedPreferences>()),
      dependsOn: [SharedPreferences],
    );

    // Servicio de conectividad
    getIt.registerLazySingleton<IConnectivityService>(() => ConnectivityServiceImpl());
  }
}


