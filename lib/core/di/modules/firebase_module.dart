import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../data/infrastructure/services/firebase_services_manager.dart';
import '../service_locator.dart';
import 'data_module.dart';
import 'domain_module.dart';

/// Módulo de registro de dependencias relacionadas a Firebase.
class FirebaseModule {
  /// Registra dependencias de Firebase y espera la inicialización asíncrona
  /// del `FirebaseServicesManager` para garantizar disponibilidad.
  static Future<void> registerAsync(GetIt getIt, {required DIEnvironment env}) async {
    // Registrar el manager como singleton
    getIt.registerLazySingleton<FirebaseServicesManager>(() => FirebaseServicesManager.instance);

    // Inicialización asíncrona segura
    final manager = getIt<FirebaseServicesManager>();
    await manager.initializeFirebase();

    // Exponer instancias de bajo nivel si se requieren en otras capas
    if (manager.auth != null && !getIt.isRegistered<FirebaseAuth>()) {
      getIt.registerSingleton<FirebaseAuth>(manager.auth!);
    }
    if (manager.firestore != null && !getIt.isRegistered<FirebaseFirestore>()) {
      getIt.registerSingleton<FirebaseFirestore>(manager.firestore!);
    }
    if (manager.storage != null && !getIt.isRegistered<FirebaseStorage>()) {
      getIt.registerSingleton<FirebaseStorage>(manager.storage!);
    }

    // Ejemplos de diferentes alcances de dependencias:
    // - factory: crea una nueva instancia cada vez
    // - lazySingleton: crea una sola vez al primer uso
    // - singleton: crea inmediatamente en el registro

    // getIt.registerFactory<SomeRepository>(() => SomeRepositoryImpl(getIt()));
    // getIt.registerLazySingleton<SomeService>(() => SomeServiceImpl(getIt()));
    // getIt.registerSingleton<AnotherService>(AnotherService());

    // Una vez inicializado Firebase, registrar DataSources y Domain que dependen de Firebase
    await DataModule.registerAsync(getIt, env: env);
    DomainModule.register(getIt, env: env);
  }
}


