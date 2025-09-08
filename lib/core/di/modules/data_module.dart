import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/datasources/firebase_auth_datasource.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/datasources/firebase_storage_datasource.dart';
import '../../../data/datasources/local_storage_datasource.dart';
import '../../../data/datasources/impl/firebase_auth_datasource_impl.dart';
import '../../../data/datasources/impl/firestore_datasource_impl.dart';
import '../../../data/datasources/impl/firebase_storage_datasource_impl.dart';
import '../../../data/datasources/impl/local_storage_datasource_impl.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/categoria_model.dart';
import '../../../data/models/content/relato_model.dart';
import '../../../data/models/content/saber_popular_model.dart';
import '../../../data/models/content/evento_cultural_model.dart';
import '../../../data/models/content/sugerencia_evento_model.dart';
import '../../di/service_locator.dart';

/// Registro de DataSources específicos y compartidos.
class DataModule {
  static Future<void> registerAsync(GetIt getIt, {required DIEnvironment env}) async {
    // Firebase Auth DataSource como singleton
    if (!getIt.isRegistered<FirebaseAuth>()) getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
    getIt.registerSingleton<FirebaseAuthDataSource>(FirebaseAuthDataSourceImpl(auth: getIt<FirebaseAuth>()));

    // Firestore genérico: registramos data sources tipados por colección
    if (!getIt.isRegistered<FirebaseFirestore>()) getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);

    // Users
    getIt.registerSingleton<FirestoreDataSource<UserModel>>(FirestoreDataSourceImpl<UserModel>(
      collectionPath: 'users',
      fromMap: (map) => UserModel.fromMap(map),
      toMap: (model) => model.toMap(),
      getId: (model) => model.id,
      firestore: getIt<FirebaseFirestore>(),
    ));

    // Categorias
    getIt.registerSingleton<FirestoreDataSource<CategoriaModel>>(FirestoreDataSourceImpl<CategoriaModel>(
      collectionPath: 'categorias',
      fromMap: (map) => CategoriaModel.fromMap(map),
      toMap: (model) => model.toMap(),
      getId: (model) => model.id,
      firestore: getIt<FirebaseFirestore>(),
    ));

    // Relatos
    getIt.registerSingleton<FirestoreDataSource<RelatoModel>>(FirestoreDataSourceImpl<RelatoModel>(
      collectionPath: 'relatos',
      fromMap: (map) => RelatoModel.fromMap(map),
      toMap: (model) => model.toMap(),
      getId: (model) => model.id,
      firestore: getIt<FirebaseFirestore>(),
    ));

    // Saberes populares
    getIt.registerSingleton<FirestoreDataSource<SaberPopularModel>>(FirestoreDataSourceImpl<SaberPopularModel>(
      collectionPath: 'saberes_populares',
      fromMap: (map) => SaberPopularModel.fromMap(map),
      toMap: (model) => model.toMap(),
      getId: (model) => model.id,
      firestore: getIt<FirebaseFirestore>(),
    ));

    // Eventos culturales
    getIt.registerSingleton<FirestoreDataSource<EventoCulturalModel>>(FirestoreDataSourceImpl<EventoCulturalModel>(
      collectionPath: 'eventos_culturales',
      fromMap: (map) => EventoCulturalModel.fromMap(map),
      toMap: (model) => model.toMap(),
      getId: (model) => model.id,
      firestore: getIt<FirebaseFirestore>(),
    ));

    // Sugerencias de eventos
    getIt.registerSingleton<FirestoreDataSource<SugerenciaEventoModel>>(FirestoreDataSourceImpl<SugerenciaEventoModel>(
      collectionPath: 'sugerencias_eventos',
      fromMap: (map) => SugerenciaEventoModel.fromMap(map),
      toMap: (model) => model.toMap(),
      getId: (model) => model.id,
      firestore: getIt<FirebaseFirestore>(),
    ));

    // Firebase Storage DataSource (ruta base configurable por tipo)
    if (!getIt.isRegistered<FirebaseStorage>()) getIt.registerSingleton<FirebaseStorage>(FirebaseStorage.instance);

    getIt.registerSingleton<FirebaseStorageDataSource>(
      FirebaseStorageDataSourceImpl(basePath: 'uploads', storage: getIt<FirebaseStorage>()),
    );

    // Local storage con SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<LocalStorageDataSource>(LocalStorageDataSourceImpl(prefs));
  }
}


