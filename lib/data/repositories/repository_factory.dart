import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/categoria_repository.dart';
import '../../domain/repositories/relato_repository.dart';
import '../../domain/repositories/evento_cultural_repository.dart';
import '../../domain/repositories/saber_popular_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/firebase_storage_datasource.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/impl/firebase_auth_datasource_impl.dart';
import '../datasources/impl/firebase_storage_datasource_impl.dart';
import '../datasources/impl/cloudinary_storage_datasource_impl.dart';
import '../datasources/impl/firestore_datasource_impl.dart';
import '../models/categoria_model.dart';
import '../models/content/relato_model.dart';
import '../models/content/saber_popular_model.dart';
import '../models/content/evento_cultural_model.dart';
import '../models/content/sugerencia_evento_model.dart';
import '../models/user_model.dart';
import 'categoria_repository_impl.dart';
import 'relato_repository_impl.dart';
import 'saber_popular_repository_impl.dart';
import 'evento_cultural_repository_impl.dart';
import 'user_repository_impl.dart';

/// Factory para crear instancias de repositorios
class RepositoryFactory {
  // Singleton
  static final RepositoryFactory _instance = RepositoryFactory._internal();
  factory RepositoryFactory() => _instance;
  RepositoryFactory._internal();

  // Datasources compartidos
  FirebaseAuthDataSource? _authDataSource;
  final Map<String, FirebaseStorageDataSource> _storageDataSources = {};
  final Map<String, dynamic> _firestoreDataSources = {};
  
  /// Obtiene o crea un datasource de autenticación
  FirebaseAuthDataSource _getAuthDataSource() {
    _authDataSource ??= FirebaseAuthDataSourceImpl();
    return _authDataSource!;
  }
  
  /// Obtiene o crea un datasource de Storage (Cloudinary por defecto)
  FirebaseStorageDataSource _getStorageDataSource({required String basePath}) {
    if (!_storageDataSources.containsKey(basePath)) {
      _storageDataSources[basePath] = CloudinaryStorageDataSourceImpl(basePath: basePath);
    }
    return _storageDataSources[basePath]!;
  }
  
  /// Obtiene o crea un datasource de Firestore
  FirestoreDataSource<T> _getFirestoreDataSource<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic>) fromMap,
    required Map<String, dynamic> Function(T) toMap,
    required String Function(T) getId,
    FirebaseFirestore? firestore,
  }) {
    final key = '$collectionPath:${T.toString()}';
    
    if (!_firestoreDataSources.containsKey(key)) {
      _firestoreDataSources[key] = FirestoreDataSourceImpl<T>(
        collectionPath: collectionPath,
        fromMap: fromMap,
        toMap: toMap,
        getId: getId,
        firestore: firestore,
      );
    }
    
    return _firestoreDataSources[key] as FirestoreDataSource<T>;
  }

  /// Crea un repositorio de usuarios
  IUserRepository createUserRepository() {
    final authDataSource = _getAuthDataSource();
    final firestoreDataSource = _getFirestoreDataSource<UserModel>(
      collectionPath: 'users',
      fromMap: UserModel.fromMap,
      toMap: (model) => model.toMap(),
      getId: (model) => model.id,
    );

    return UserRepositoryImpl(
      authDataSource: authDataSource,
      firestoreDataSource: firestoreDataSource,
    );
  }

  /// Crea un repositorio de categorías
  ICategoriaRepository createCategoriaRepository() {
    final firestoreDataSource = _getFirestoreDataSource<CategoriaModel>(
      collectionPath: 'categorias',
      fromMap: CategoriaModel.fromMap,
      toMap: (model) => model.toMap(),
      getId: (model) => model.id,
    );

    return CategoriaRepositoryImpl(
      dataSource: firestoreDataSource,
    );
  }

  /// Crea un repositorio de relatos
  IRelatoRepository createRelatoRepository() {
    final firestoreDataSource = _getFirestoreDataSource<RelatoModel>(
      collectionPath: 'relatos',
      fromMap: RelatoModel.fromMap,
      toMap: (model) => model.toMap(),
      getId: (model) => model.id,
    );
    
    final storageDataSource = _getStorageDataSource(basePath: 'relatos');

    return RelatoRepositoryImpl(
      firestoreDataSource: firestoreDataSource,
      storageDataSource: storageDataSource,
    );
  }
  
  /// Crea un repositorio de saberes populares
  ISaberPopularRepository createSaberPopularRepository() {
    final firestoreDataSource = _getFirestoreDataSource<SaberPopularModel>(
      collectionPath: 'saberes_populares',
      fromMap: SaberPopularModel.fromMap,
      toMap: (model) => model.toMap(),
      getId: (model) => model.id,
    );
    
    final storageDataSource = _getStorageDataSource(basePath: 'saberes_populares');

    return SaberPopularRepositoryImpl(
      firestoreDataSource: firestoreDataSource,
      storageDataSource: storageDataSource,
    );
  }
  
  /// Crea un repositorio de eventos culturales
  IEventoCulturalRepository createEventoCulturalRepository() {
    final firestoreEventos = _getFirestoreDataSource<EventoCulturalModel>(
      collectionPath: 'eventos_culturales',
      fromMap: EventoCulturalModel.fromMap,
      toMap: (model) => model.toMap(),
      getId: (model) => model.id,
    );

    final firestoreSugerencias = _getFirestoreDataSource<SugerenciaEventoModel>(
      collectionPath: 'sugerencias_eventos',
      fromMap: SugerenciaEventoModel.fromMap,
      toMap: (model) => model.toMap(),
      getId: (model) => model.id,
    );

    final storageDataSource = _getStorageDataSource(basePath: 'eventos_culturales');

    return EventoCulturalRepositoryImpl(
      firestoreEventos: firestoreEventos,
      firestoreSugerencias: firestoreSugerencias,
      storageDataSource: storageDataSource,
    );
  }
  
  // TODO: Agregar métodos para crear otros repositorios
}
