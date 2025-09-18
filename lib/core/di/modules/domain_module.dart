import 'package:get_it/get_it.dart';

import '../../../domain/validators/contenido_validator.dart';
import '../../../domain/services/i_analytics_service.dart';
import '../../../data/infrastructure/services/analytics_service_impl.dart';

// Repositorios (interfaces)
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/repositories/categoria_repository.dart';
import '../../../domain/repositories/relato_repository.dart';
import '../../../domain/repositories/saber_popular_repository.dart';
import '../../../domain/repositories/evento_cultural_repository.dart';

// Implementaciones de repositorios
import '../../../data/repositories/user_repository_impl.dart';
import '../../../data/repositories/categoria_repository_impl.dart';
import '../../../data/repositories/relato_repository_impl.dart';
import '../../../data/repositories/saber_popular_repository_impl.dart';
import '../../../data/repositories/evento_cultural_repository_impl.dart';
import '../../../data/repositories/offline_relato_repository.dart';
import '../../../data/repositories/offline_saber_repository.dart';
import '../../../data/repositories/offline_evento_repository.dart';

// DataSources necesarios por repositorios
import '../../../data/datasources/firebase_auth_datasource.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/datasources/firebase_storage_datasource.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/categoria_model.dart';
import '../../../data/models/content/relato_model.dart';
import '../../../data/models/content/saber_popular_model.dart';
import '../../../data/models/content/evento_cultural_model.dart';
import '../../../data/models/content/sugerencia_evento_model.dart';

// Casos de uso - Auth
import '../../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../../domain/usecases/auth/login_with_email_usecase.dart';
import '../../../domain/usecases/auth/login_with_google_usecase.dart';
import '../../../domain/usecases/auth/register_user_usecase.dart';
import '../../../domain/usecases/auth/logout_usecase.dart';

// Casos de uso - Relatos
import '../../../domain/usecases/relatos/crear_relato_usecase.dart';
import '../../../domain/usecases/relatos/actualizar_relato_usecase.dart';
import '../../../domain/usecases/relatos/eliminar_relato_usecase.dart';
import '../../../domain/usecases/relatos/reportar_relato_usecase.dart';
import '../../../domain/usecases/relatos/moderar_relato_usecase.dart';
import '../../../domain/usecases/relatos/obtener_relatos_usecase.dart';
import '../../../domain/usecases/relatos/dar_like_relato_usecase.dart';
import '../../../domain/usecases/relatos/toggle_like_relato_usecase.dart';
import '../../../domain/usecases/relatos/registrar_compartido_relato_usecase.dart';

// Casos de uso - Saberes Populares
import '../../../domain/usecases/saberes/crear_saber_usecase.dart';
import '../../../domain/usecases/saberes/actualizar_saber_usecase.dart';
import '../../../domain/usecases/saberes/eliminar_saber_usecase.dart';
import '../../../domain/usecases/saberes/moderar_saber_usecase.dart';
import '../../../domain/usecases/saberes/obtener_saberes_usecase.dart';

// Casos de uso - Eventos Culturales
import '../../../domain/usecases/eventos/crear_evento_usecase.dart';
import '../../../domain/usecases/eventos/actualizar_evento_usecase.dart';
import '../../../domain/usecases/eventos/eliminar_evento_usecase.dart';
import '../../../domain/usecases/eventos/obtener_eventos_usecase.dart';
import '../../../domain/usecases/eventos/buscar_eventos_usecase.dart';
import '../../../domain/usecases/eventos/crear_sugerencia_usecase.dart';
import '../../../domain/usecases/eventos/procesar_sugerencia_usecase.dart';
import '../../../domain/usecases/eventos/obtener_sugerencias_pendientes_usecase.dart';
import '../../../domain/usecases/eventos/obtener_eventos_carrusel_por_categoria_usecase.dart';
import '../../../domain/usecases/eventos/obtener_eventos_por_rango_y_busqueda_usecase.dart';
import '../../../domain/usecases/eventos/obtener_marcadores_por_mes_usecase.dart';
// Casos de uso - Categorías
import '../../../domain/usecases/categorias/obtener_categorias_usecase.dart';
import '../../../domain/usecases/categorias/obtener_categorias_por_tipo_usecase.dart';

import '../../di/service_locator.dart';
import '../../../domain/services/i_sync_queue.dart';
import '../../../data/infrastructure/services/sync_worker.dart';
import '../../../domain/factories/auth_usecase_factory.dart';
import '../../../domain/factories/relato_usecase_factory.dart';
import '../../../domain/factories/saber_popular_usecase_factory.dart';
import '../../../domain/factories/evento_usecase_factory.dart';
import '../../../domain/factories/usecases.dart';

/// Registro de repositorios, validadores y casos de uso.
class DomainModule {
  static void register(GetIt getIt, {required DIEnvironment env}) {
    _registerRepositories(getIt);
    _registerValidators(getIt);
    _registerUseCases(getIt);
  }

  static void _registerRepositories(GetIt getIt) {
    // UserRepository
    getIt.registerLazySingleton<IUserRepository>(() => UserRepositoryImpl(
          authDataSource: getIt<FirebaseAuthDataSource>(),
          firestoreDataSource: getIt<FirestoreDataSource<UserModel>>(),
        ));

    // CategoriaRepository
    getIt.registerLazySingleton<ICategoriaRepository>(() => CategoriaRepositoryImpl(
          dataSource: getIt<FirestoreDataSource<CategoriaModel>>(),
        ));

    // RelatoRepository con wrapper offline
    getIt.registerLazySingleton<IRelatoRepository>(() {
      final remote = RelatoRepositoryImpl(
        firestoreDataSource: getIt<FirestoreDataSource<RelatoModel>>(),
        storageDataSource: getIt<FirebaseStorageDataSource>(),
      );
      return OfflineRelatoRepository(remote, getIt<ISyncQueue>());
    });

    // SaberPopularRepository con wrapper offline
    getIt.registerLazySingleton<ISaberPopularRepository>(() {
      final remote = SaberPopularRepositoryImpl(
        firestoreDataSource: getIt<FirestoreDataSource<SaberPopularModel>>(),
        storageDataSource: getIt<FirebaseStorageDataSource>(),
      );
      return OfflineSaberRepository(remote, getIt<ISyncQueue>());
    });

    // EventoCulturalRepository con wrapper offline (server-wins)
    getIt.registerLazySingleton<IEventoCulturalRepository>(() {
      final remote = EventoCulturalRepositoryImpl(
        firestoreEventos: getIt<FirestoreDataSource<EventoCulturalModel>>(),
        firestoreSugerencias: getIt<FirestoreDataSource<SugerenciaEventoModel>>(),
        storageDataSource: getIt<FirebaseStorageDataSource>(),
      );
      return OfflineEventoRepository(remote, getIt<ISyncQueue>());
    });
  }

  static void _registerValidators(GetIt getIt) {
    // Validador de contenido como factory (stateless, barato)
    getIt.registerFactory<ContenidoValidator>(() => ContenidoValidator());

    // AnalyticsService como lazySingleton (depende de FirebaseServicesManager via impl)
    if (!getIt.isRegistered<IAnalyticsService>()) {
      getIt.registerLazySingleton<IAnalyticsService>(() => AnalyticsServiceImpl(getIt()));
    }
  }

  static void _registerUseCases(GetIt getIt) {
    // Auth
    getIt.registerFactory<GetCurrentUserUseCase>(() => GetCurrentUserUseCase(getIt<IUserRepository>()));
    getIt.registerFactory<LoginWithEmailUseCase>(() => LoginWithEmailUseCase(getIt<IUserRepository>()));
    getIt.registerFactory<LoginWithGoogleUseCase>(() => LoginWithGoogleUseCase(getIt<IUserRepository>()));
    getIt.registerFactory<RegisterUserUseCase>(() => RegisterUserUseCase(getIt<IUserRepository>()));
    getIt.registerFactory<LogoutUseCase>(() => LogoutUseCase(getIt<IUserRepository>()));

    // Relatos
    getIt.registerFactory<CrearRelatoUseCase>(() => CrearRelatoUseCase(
          getIt<IRelatoRepository>(),
          getIt<ICategoriaRepository>(),
          getIt<IUserRepository>(),
          getIt<ContenidoValidator>(),
        ));
    getIt.registerFactory<ActualizarRelatoUseCase>(() => ActualizarRelatoUseCase(
          getIt<IRelatoRepository>(),
          getIt<ICategoriaRepository>(),
          getIt<IUserRepository>(),
          getIt<ContenidoValidator>(),
        ));
    getIt.registerFactory<EliminarRelatoUseCase>(() => EliminarRelatoUseCase(
          getIt<IRelatoRepository>(),
          getIt<IUserRepository>(),
        ));
    getIt.registerFactory<ReportarRelatoUseCase>(() => ReportarRelatoUseCase(
          getIt<IRelatoRepository>(),
          getIt<IUserRepository>(),
        ));
    getIt.registerFactory<ModerarRelatoUseCase>(() => ModerarRelatoUseCase(
          getIt<IRelatoRepository>(),
          getIt<IUserRepository>(),
        ));
    getIt.registerFactory<ObtenerRelatosUseCase>(() => ObtenerRelatosUseCase(getIt<IRelatoRepository>()));
    getIt.registerFactory<DarLikeRelatoUseCase>(() => DarLikeRelatoUseCase(getIt<IRelatoRepository>()));
    getIt.registerFactory<ToggleLikeRelatoUseCase>(() => ToggleLikeRelatoUseCase(getIt<IRelatoRepository>()));
    getIt.registerFactory<RegistrarCompartidoRelatoUseCase>(() => RegistrarCompartidoRelatoUseCase(getIt<IRelatoRepository>()));

    // Saberes Populares
    getIt.registerFactory<CrearSaberUseCase>(() => CrearSaberUseCase(
          getIt<ISaberPopularRepository>(),
          getIt<ICategoriaRepository>(),
          getIt<IUserRepository>(),
          getIt<ContenidoValidator>(),
        ));
    getIt.registerFactory<ActualizarSaberUseCase>(() => ActualizarSaberUseCase(
          getIt<ISaberPopularRepository>(),
          getIt<ICategoriaRepository>(),
          getIt<IUserRepository>(),
          getIt<ContenidoValidator>(),
        ));
    getIt.registerFactory<EliminarSaberUseCase>(() => EliminarSaberUseCase(
          getIt<ISaberPopularRepository>(),
          getIt<IUserRepository>(),
        ));
    getIt.registerFactory<ModerarSaberUseCase>(() => ModerarSaberUseCase(
          getIt<ISaberPopularRepository>(),
          getIt<IUserRepository>(),
        ));
    getIt.registerFactory<ObtenerSaberesUseCase>(() => ObtenerSaberesUseCase(getIt<ISaberPopularRepository>()));

    // Eventos Culturales
    getIt.registerFactory<CrearEventoUseCase>(() => CrearEventoUseCase(
          getIt<IEventoCulturalRepository>(),
          getIt<ICategoriaRepository>(),
          getIt<IUserRepository>(),
          getIt<ContenidoValidator>(),
        ));
    getIt.registerFactory<ActualizarEventoUseCase>(() => ActualizarEventoUseCase(
          getIt<IEventoCulturalRepository>(),
          getIt<ICategoriaRepository>(),
          getIt<IUserRepository>(),
        ));
    getIt.registerFactory<EliminarEventoUseCase>(() => EliminarEventoUseCase(
          getIt<IEventoCulturalRepository>(),
          getIt<IUserRepository>(),
        ));
    getIt.registerFactory<ObtenerEventosUseCase>(() => ObtenerEventosUseCase(getIt<IEventoCulturalRepository>()));
    getIt.registerFactory<BuscarEventosUseCase>(() => BuscarEventosUseCase(getIt<IEventoCulturalRepository>()));
    getIt.registerFactory<ObtenerEventosCarruselPorCategoriaUseCase>(() =>
        ObtenerEventosCarruselPorCategoriaUseCase(getIt<IEventoCulturalRepository>()));
    getIt.registerFactory<ObtenerEventosPorRangoYBusquedaUseCase>(() =>
        ObtenerEventosPorRangoYBusquedaUseCase(getIt<IEventoCulturalRepository>()));
    getIt.registerFactory<ObtenerMarcadoresPorMesUseCase>(() =>
        ObtenerMarcadoresPorMesUseCase(getIt<IEventoCulturalRepository>()));
    getIt.registerFactory<CrearSugerenciaUseCase>(() => CrearSugerenciaUseCase(
          getIt<IEventoCulturalRepository>(),
          getIt<ICategoriaRepository>(),
          getIt<IUserRepository>(),
          getIt<ContenidoValidator>(),
        ));
    getIt.registerFactory<ProcesarSugerenciaUseCase>(() => ProcesarSugerenciaUseCase(
          getIt<IEventoCulturalRepository>(),
          getIt<IUserRepository>(),
        ));
    getIt.registerFactory<ObtenerSugerenciasPendientesUseCase>(
        () => ObtenerSugerenciasPendientesUseCase(getIt<IEventoCulturalRepository>()));

    // Categorías
    getIt.registerFactory<ObtenerCategoriasUseCase>(() => ObtenerCategoriasUseCase(getIt<ICategoriaRepository>()));
    getIt.registerFactory<ObtenerCategoriasPorTipoUseCase>(() => ObtenerCategoriasPorTipoUseCase(getIt<ICategoriaRepository>()));

    // Factories de casos de uso por dominio (lazySingletons para reutilizar)
    if (!getIt.isRegistered<AuthUseCaseFactory>()) {
      getIt.registerLazySingleton<AuthUseCaseFactory>(() => AuthUseCaseFactory(getIt: getIt));
    }
    if (!getIt.isRegistered<RelatoUseCaseFactory>()) {
      getIt.registerLazySingleton<RelatoUseCaseFactory>(() => RelatoUseCaseFactory(getIt: getIt));
    }
    if (!getIt.isRegistered<SaberPopularUseCaseFactory>()) {
      getIt.registerLazySingleton<SaberPopularUseCaseFactory>(() => SaberPopularUseCaseFactory(getIt: getIt));
    }
    if (!getIt.isRegistered<EventoUseCaseFactory>()) {
      getIt.registerLazySingleton<EventoUseCaseFactory>(() => EventoUseCaseFactory(getIt: getIt));
    }

    // Agregador UseCases
    if (!getIt.isRegistered<UseCases>()) {
      getIt.registerLazySingleton<UseCases>(() => UseCases(getIt: getIt));
    }

    // Sync worker
    if (!getIt.isRegistered<SyncWorker>()) {
      getIt.registerLazySingleton<SyncWorker>(() => SyncWorker(
            getIt<ISyncQueue>(),
            getIt<IRelatoRepository>(),
            getIt<ISaberPopularRepository>(),
            getIt<IEventoCulturalRepository>(),
          )..start());
    }
  }
}


