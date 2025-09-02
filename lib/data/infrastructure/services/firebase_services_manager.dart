
import 'package:flutter/foundation.dart';
import 'firebase_messaging_service.dart';
import 'firebase_performance_service.dart';
import 'firebase_crashlytics_service.dart';
import 'firebase_functions_service.dart';

class FirebaseServicesManager {
  static final FirebaseServicesManager _instance = FirebaseServicesManager._internal();
  factory FirebaseServicesManager() => _instance;
  FirebaseServicesManager._internal();

  late final FirebaseMessagingService messaging;
  late final FirebasePerformanceService performance;
  late final FirebaseCrashlyticsService crashlytics;
  late final FirebaseFunctionsService functions;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializar servicios
      messaging = FirebaseMessagingService();
      performance = FirebasePerformanceService();
      crashlytics = FirebaseCrashlyticsService();
      functions = FirebaseFunctionsService();

      // Inicializar cada servicio
      await Future.wait([
        messaging.initialize(),
        performance.initialize(),
        crashlytics.initialize(),
      ]);

      _isInitialized = true;
      
      if (kDebugMode) {
        print('Firebase Services Manager initialized successfully');
      }
    } catch (error, stack) {
      if (kDebugMode) {
        print('Error initializing Firebase Services: $error');
      }
      // Registrar el error en Crashlytics si ya está inicializado
      if (_isInitialized) {
        await crashlytics.recordError(error, stack);
      }
      rethrow;
    }
  }

  // Método para medir el rendimiento de una operación
  Future<T> measureOperation<T>({
    required String operationName,
    required Future<T> Function() operation,
    Map<String, String>? metrics,
  }) async {
    performance.startContentLoadTrace(operationName);
    try {
      final result = await operation();
      await performance.stopContentLoadTrace(metrics: metrics);
      return result;
    } catch (error, stack) {
      await crashlytics.recordError(error, stack);
      rethrow;
    }
  }

  // Método para enviar notificación a usuarios específicos
  Future<void> sendNotificationToUsers(List<String> userIds, String title, String body) async {
    try {
      await functions.callFunction(
        'sendNotification',
        parameters: {
          'userIds': userIds,
          'notification': {
            'title': title,
            'body': body,
          },
        },
      );
    } catch (error, stack) {
      await crashlytics.recordError(error, stack);
      rethrow;
    }
  }

  // Método para registrar eventos importantes
  Future<void> logImportantEvent(String eventName, Map<String, dynamic> parameters) async {
    try {
      await crashlytics.log('Event: $eventName - Parameters: $parameters');
    } catch (error, stack) {
      print('Error logging event: $error');
      await crashlytics.recordError(error, stack);
    }
  }

  void dispose() {
    messaging.dispose();
  }
}
