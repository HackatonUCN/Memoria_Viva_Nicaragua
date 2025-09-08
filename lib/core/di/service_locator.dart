import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'di_errors.dart';
import 'modules/core_module.dart';
import 'modules/firebase_module.dart';

/// Entornos soportados para configurar dependencias condicionalmente.
enum DIEnvironment {
  dev,
  staging,
  production,
}

/// Contenedor singleton de inyección de dependencias basado en GetIt.
///
/// - Inicialización asíncrona con manejo de errores
/// - Organización por módulos de registro (Core, Firebase, Features)
/// - Métodos para reset completo/parcial (útil para logout)
/// - Verificación de estado de inicialización
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();
  static final GetIt _getIt = GetIt.I;

  bool _initialized = false;
  DIEnvironment _currentEnv = DIEnvironment.dev;
  Completer<void>? _initCompleter;

  /// Inicializa el contenedor e instala los módulos base.
  ///
  /// Usa inicialización asíncrona para recursos que lo requieran (p.ej. Firebase).
  Future<void> initialize({
    DIEnvironment environment = DIEnvironment.dev,
    bool enableFirebaseModule = true,
  }) async {
    if (_initialized) return;

    _currentEnv = environment;
    diDebugLog('Inicializando ServiceLocator en env=$_currentEnv');

    try {
      _initCompleter = Completer<void>();
      // Registro base (sincrónico)
      CoreModule.register(_getIt, env: _currentEnv);

      // Registro condicional de módulos
      if (enableFirebaseModule) {
        await FirebaseModule.registerAsync(_getIt, env: _currentEnv);
      }

      _initialized = true;
      diDebugLog('ServiceLocator inicializado correctamente');
      _initCompleter?.complete();
    } catch (error, stack) {
      _initialized = false;
      diDebugLog('Error inicializando ServiceLocator', error: error);
      _initCompleter?.completeError(error, stack);
      throw DIException('Fallo en la inicialización del contenedor', cause: error, stackTrace: stack);
    }
  }

  /// Devuelve si el contenedor ha sido completamente inicializado.
  bool get isInitialized => _initialized;

  /// Entorno actual del contenedor.
  DIEnvironment get currentEnvironment => _currentEnv;

  /// Devuelve un Future que completa cuando el contenedor está listo.
  Future<void> whenInitialized() {
    if (_initialized) return Future.value();
    _initCompleter ??= Completer<void>();
    return _initCompleter!.future;
    }

  /// Re-registra módulos seleccionados luego de un logout o limpieza.
  /// Por defecto hace un reset completo y reinstala módulos base.
  Future<void> reset({bool reinstall = true}) async {
    diDebugLog('Reset del ServiceLocator (reinstall=$reinstall)');
    try {
      await _getIt.reset(dispose: true);
      _initialized = false;
      if (reinstall) {
        await initialize(environment: _currentEnv);
      }
    } catch (error, stack) {
      throw DIException('Fallo en reset del contenedor', cause: error, stackTrace: stack);
    }
  }

  /// Limpieza parcial para escenarios como logout: elimina singletons específicos por instancia.
  /// Nota: Para eliminar por tipo, obtén la instancia y pásala aquí.
  Future<void> resetScope({List<Object>? instances}) async {
    try {
      if (instances == null || instances.isEmpty) {
        // Sin parámetros, no hacer nada para evitar borrar todo por accidente.
        return;
      }
      for (final target in instances) {
        _getIt.unregister(instance: target);
      }
    } catch (error, stack) {
      throw DIException('Fallo en resetScope', cause: error, stackTrace: stack);
    }
  }

  // Exponer una forma centralizada de obtener dependencias, útil para test/mocks.
  static T get<T extends Object>() => _getIt<T>();
}


