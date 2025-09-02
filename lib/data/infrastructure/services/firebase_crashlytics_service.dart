import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseCrashlyticsService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> initialize() async {
    // En la web, Crashlytics puede no estar disponible
    if (kIsWeb) {
      print('Crashlytics no está disponible en la web');
      return;
    }

    try {
      // Pasar todos los errores de Flutter a Crashlytics
      FlutterError.onError = _crashlytics.recordFlutterError;

      // Habilitar la recopilación de Crashlytics
      await _crashlytics.setCrashlyticsCollectionEnabled(true);

      // Configurar información del usuario actual si está disponible
      // await _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      print('Error inicializando Crashlytics: $e');
    }
  }

  // Registrar un error
  Future<void> recordError(
    dynamic error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (kIsWeb) {
      print('Error en web: $error');
      return;
    }

    try {
      await _crashlytics.recordError(
        error,
        stack,
        reason: reason ?? (fatal ? 'Error fatal capturado' : 'Error no fatal capturado'),
        fatal: fatal,
      );
    } catch (e) {
      print('Error registrando en Crashlytics: $e');
    }
  }

  // Establecer atributos personalizados
  Future<void> setCustomKey(String key, dynamic value) async {
    if (kIsWeb) {
      print('Crashlytics setCustomKey en web: $key = $value');
      return;
    }

    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      print('Error estableciendo custom key en Crashlytics: $e');
    }
  }

  // Establecer el ID del usuario actual
  Future<void> setUserIdentifier(String userId) async {
    if (kIsWeb) {
      print('Crashlytics setUserIdentifier en web: $userId');
      return;
    }

    try {
      await _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      print('Error estableciendo user identifier en Crashlytics: $e');
    }
  }

  // Registrar un mensaje de log
  Future<void> log(String message) async {
    if (kIsWeb) {
      print('Crashlytics log en web: $message');
      return;
    }

    try {
      await _crashlytics.log(message);
    } catch (e) {
      print('Error registrando log en Crashlytics: $e');
    }
  }

  // Forzar un crash para pruebas
  void forceCrash() {
    if (kDebugMode && !kIsWeb) {
      _crashlytics.crash();
    }
  }

  // Manejar errores asíncronos
  Future<void> handleAsyncError(Future<void> Function() asyncFunction) async {
    try {
      await asyncFunction();
    } catch (error, stack) {
      await recordError(error, stack);
      rethrow;
    }
  }
}
