import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart' as perf;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:google_api_availability/google_api_availability.dart';

import 'firebase_messaging_service.dart';
import 'firebase_performance_service.dart';
import 'firebase_crashlytics_service.dart';
import 'firebase_functions_service.dart';
import 'firebase_options.dart';
import 'package:memoria_viva_nicaragua/core/config/environment.dart' as env;

/// Gestor centralizado de servicios de Firebase.
///
/// - Singleton
/// - Inicialización multiplataforma (Android, iOS, Web, desktop soportados)
/// - Configuración condicional por plataforma y manejo básico de errores
class FirebaseServicesManager {
  static FirebaseServicesManager? _instance;
  static FirebaseServicesManager get instance => _instance ??= FirebaseServicesManager._();

  FirebaseServicesManager._();

  // Servicios básicos
  FirebaseApp? _app;
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  FirebaseStorage? _storage;
  FirebaseAnalytics? _analytics;
  FirebaseRemoteConfig? _remoteConfig;
  fcm.FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Servicios auxiliares existentes
  FirebaseMessagingService? messaging;
  FirebasePerformanceService? performance;
  FirebaseCrashlyticsService? crashlytics;
  FirebaseFunctionsService? functions;

  bool _isInitialized = false;
  bool _crashlyticsEnabled = false;
  bool _analyticsEnabled = false;
  bool _performanceEnabled = false;
  bool _privacyConsentGranted = false;

  /// Inicialización centralizada de Firebase Core y servicios básicos.
  /// Incluye manejo de errores y fallbacks por plataforma.
  Future<void> initializeFirebase() async {
    if (_isInitialized) return;

    try {
      // 1) Inicializar Core con opciones por plataforma
      _app = await _initializeCore();

      // 2) Configurar servicios según disponibilidad
      _configureAuth();
      _configureFirestore();
      _configureStorage();

      // 3) Inicializar servicios auxiliares disponibles
      await _initializeAuxiliaryServices();

      // 4) Configurar monitoreo y analytics por entorno
      await configureCrashlytics();
      await configurePerformance();
      await configureAnalytics();
      await configureMessaging();
      await configureRemoteConfig();

      // Seed de categorías desactivado (se manejará manualmente)

      _isInitialized = true;

      if (kDebugMode) debugPrint('[Firebase] Initialized on ${currentPlatform}');
    } catch (error, stack) {
      // Logging centralizado
      debugPrint('[Firebase] Initialization error: $error');

      // Intentar registrar en Crashlytics si es posible
      try {
        if (crashlytics != null) {
          await crashlytics!.recordError(error, stack);
        }
      } catch (_) {
        // Ignorar errores de crashlytics durante init
      }

      // Notificación básica de problema (solo debug)
      if (kDebugMode) {
        debugPrint('[Firebase] Some services may not be available. App continues.');
      }
    }
  }

  bool get isInitialized => _isInitialized;

  String get currentPlatform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  FirebaseAuth? get auth => _auth;
  FirebaseFirestore? get firestore => _firestore;
  FirebaseStorage? get storage => _storage;
  FirebaseAnalytics? get analytics => _analytics;
  FirebaseRemoteConfig? get remoteConfig => _remoteConfig;
  bool get privacyConsentGranted => _privacyConsentGranted;

  /// Guarda el token del dispositivo en Firestore bajo users/{uid}/fcmTokens/{token}
  Future<void> saveDeviceToken({required String userId}) async {
    try {
      final token = await getDeviceToken();
      if (token == null) return;
      final tokensCol = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('fcmTokens');
      await tokensCol.doc(token).set({
        'createdAt': FieldValue.serverTimestamp(),
        'platform': currentPlatform,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FCM] No se pudo guardar el token: $e');
    }
  }

  // ----- Internals -----

  Future<FirebaseApp> _initializeCore() async {
    // Si ya existe una app inicializada, reutilizarla
    try {
      final existing = Firebase.apps.isNotEmpty ? Firebase.apps.first : null;
      if (existing != null) return existing;
    } catch (_) {}

    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void _configureAuth() {
    try {
      _auth = FirebaseAuth.instance;
    } catch (e) {
      debugPrint('[Firebase][Auth] Not available on ${currentPlatform}: $e');
      _auth = null; // Fallback: servicio no disponible
    }
  }

  void _configureFirestore() {
    try {
      _firestore = FirebaseFirestore.instance;

      // Configuraciones condicionales por plataforma/entorno
      // En web, habilitar cache persistente según soporte
      if (kIsWeb) {
        _firestore!.settings = const Settings(persistenceEnabled: true);
      }
    } catch (e) {
      debugPrint('[Firebase][Firestore] Not available on ${currentPlatform}: $e');
      _firestore = null;
    }
  }

  void _configureStorage() {
    try {
      _storage = FirebaseStorage.instance;
    } catch (e) {
      debugPrint('[Firebase][Storage] Not available on ${currentPlatform}: $e');
      _storage = null;
    }
  }

  Future<void> _initializeAuxiliaryServices() async {
    // Estos servicios son opcionales; si fallan, no bloquean la app.
    try {
      messaging = FirebaseMessagingService();
      performance = FirebasePerformanceService();
      crashlytics = FirebaseCrashlyticsService();
      functions = FirebaseFunctionsService();

      await Future.wait([
        // Algunos servicios pueden no estar soportados en web/desktop
        _safeInit(() => messaging!.initialize()),
        _safeInit(() => performance!.initialize()),
        _safeInit(() => crashlytics!.initialize()),
      ]);
    } catch (e) {
      // No rethrow: estos son complementarios
      debugPrint('[Firebase][Aux] Initialization partial failure: $e');
    }
  }

  Future<void> _safeInit(Future<void> Function() init) async {
    try {
      await init();
    } catch (e) {
      debugPrint('[Firebase][Aux] Skipping service: $e');
    }
  }

  // APIs utilitarias anteriores conservadas para compatibilidad
  Future<T> measureOperation<T>({
    required String operationName,
    required Future<T> Function() operation,
    Map<String, String>? metrics,
  }) async {
    if (performance == null) return await operation();
    performance!.startContentLoadTrace(operationName);
    try {
      final result = await operation();
      await performance!.stopContentLoadTrace(metrics: metrics);
      return result;
    } catch (error, stack) {
      if (crashlytics != null) {
        await crashlytics!.recordError(error, stack);
      }
      rethrow;
    }
  }

  Future<void> sendNotificationToUsers(List<String> userIds, String title, String body) async {
    try {
      await functions?.callFunction(
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
      if (crashlytics != null) {
        await crashlytics!.recordError(error, stack);
      }
      rethrow;
    }
  }

  Future<void> logImportantEvent(String eventName, Map<String, dynamic> parameters) async {
    try {
      await crashlytics?.log('Event: $eventName - Parameters: $parameters');
    } catch (error, stack) {
      debugPrint('Error logging event: $error');
      if (crashlytics != null) {
        await crashlytics!.recordError(error, stack);
      }
    }
  }

  void dispose() {
    try {
      messaging?.dispose();
    } catch (_) {}
  }

  // ==========================
  // Monitoreo y Analytics
  // ==========================

  /// Configura Crashlytics con manejo por entorno y capturas globales.
  /// - Habilita en Release, deshabilita en Debug por defecto
  /// - Redirige errores de Flutter y de plataforma a Crashlytics
  Future<void> configureCrashlytics() async {
    // Crashlytics no está disponible en Web actualmente
    if (kIsWeb) {
      debugPrint('[Crashlytics] No disponible en Web');
      _crashlyticsEnabled = false;
      return;
    }

    try {
      final bool enable = kReleaseMode; // Ajuste por entorno
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enable);
      _crashlyticsEnabled = enable;

      if (enable) {
        // Capturar errores de Flutter
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

        // Capturar errores no controlados (síncronos/asíncronos) a nivel de plataforma
        PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };

        // Breadcrumb inicial
        await FirebaseCrashlytics.instance.log('Crashlytics habilitado (${currentPlatform})');
      } else {
        // En debug, mantener logs en consola como ayuda
        debugPrint('[Crashlytics] Deshabilitado en Debug');
      }
    } catch (e) {
      debugPrint('[Crashlytics] Error en configuración: $e');
    }
  }

  /// Configura Firebase Analytics con manejo por entorno y consentimiento básico.
  /// - Habilita en Release por defecto; en Debug se puede mantener deshabilitado
  /// - Permite registrar eventos personalizados y propiedades de usuario
  Future<void> configureAnalytics() async {
    try {
      // Evitar Analytics si en Android no hay Google Play Services
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final availability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
        if (availability != GooglePlayServicesAvailability.success) {
          debugPrint('[Analytics] Google Play Services no disponible ($availability). Omitiendo Analytics.');
          _analyticsEnabled = false;
          return;
        }
      }

      _analytics = FirebaseAnalytics.instance;
      final bool enable = kReleaseMode && _privacyConsentGranted; // Ajuste por entorno + consentimiento
      await _analytics!.setAnalyticsCollectionEnabled(enable);
      _analyticsEnabled = enable;

      if (enable) {
        // Evento de app abierta
        await _analytics!.logAppOpen();
      } else {
        debugPrint('[Analytics] Deshabilitado en Debug');
      }
    } catch (e) {
      debugPrint('[Analytics] Error en configuración: $e');
      _analyticsEnabled = false;
    }
  }

  /// Configura Firebase Performance con manejo por entorno.
  /// - Habilita en Release por defecto
  /// - Permite traces personalizados vía FirebasePerformanceService
  Future<void> configurePerformance() async {
    try {
      // Evitar Performance si en Android no hay Google Play Services
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final availability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
        if (availability != GooglePlayServicesAvailability.success) {
          debugPrint('[Performance] Google Play Services no disponible ($availability). Omitiendo Performance.');
          _performanceEnabled = false;
          return;
        }
      }

      final bool enable = kReleaseMode && _privacyConsentGranted; // Ajuste por entorno + consentimiento
      await perf.FirebasePerformance.instance.setPerformanceCollectionEnabled(enable);
      _performanceEnabled = enable;

      if (!enable) {
        debugPrint('[Performance] Deshabilitado en Debug');
      }
    } catch (e) {
      debugPrint('[Performance] Error en configuración: $e');
      _performanceEnabled = false;
    }
  }

  /// Registra un error con logging detallado y Crashlytics (si está habilitado).
  Future<void> logError(String message, {Object? error, StackTrace? stackTrace}) async {
    debugPrint('[Error] $message${error != null ? ' -> $error' : ''}');
    if (_crashlyticsEnabled && !kIsWeb) {
      try {
        await FirebaseCrashlytics.instance.log(message);
        if (error != null) {
          await FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: false);
        }
      } catch (_) {}
    }
  }

  /// Registra un evento de Analytics y lo deja como breadcrumb en Crashlytics.
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    // Log local para debugging
    if (kDebugMode) {
      debugPrint('[Analytics][event] $name params=${parameters ?? {}}');
    }

    // Analytics
    if (_analyticsEnabled && _analytics != null) {
      try {
        await _analytics!.logEvent(name: name, parameters: parameters);
      } catch (e) {
        debugPrint('[Analytics] logEvent error: $e');
      }
    }

    // Breadcrumb en Crashlytics
    if (_crashlyticsEnabled && !kIsWeb) {
      try {
        await FirebaseCrashlytics.instance.log('event:$name ${parameters ?? {}}');
      } catch (_) {}
    }
  }

  // ==========================
  // Privacidad y usuario
  // ==========================

  /// Actualiza el consentimiento de privacidad del usuario.
  /// Si cambia, reconfigura Analytics y Performance en consecuencia.
  Future<void> setPrivacyConsent({required bool granted}) async {
    _privacyConsentGranted = granted;
    try {
      // Reconfigurar analytics y performance ante cambios de consentimiento
      await configureAnalytics();
      await configurePerformance();
      // Crashlytics no depende de consentimiento en todas las jurisdicciones, pero lo respetamos si decides atarlo
      // Aquí podrías también condicionar Crashlytics si tu política lo requiere
    } catch (e) {
      debugPrint('[Privacy] Error aplicando consentimiento: $e');
    }
  }

  // ==========================
  // Notificaciones (FCM) y Local Notifications
  // ==========================

  /// Configura FCM (permisos, handlers y notificaciones locales).
  Future<void> configureMessaging() async {
    try {
      // En Android, FCM requiere Google Play Services. Evitar configuración si no está disponible
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final availability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
        if (availability != GooglePlayServicesAvailability.success) {
          debugPrint('[Messaging] Google Play Services no disponible ($availability). Omitiendo FCM.');
          return;
        }
      }

      _messaging ??= fcm.FirebaseMessaging.instance;
      // Inicializar plugin de notificaciones locales
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iOSSettings,
      );
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          // Aquí puedes manejar deep links o navegación según el payload
          if (kDebugMode) debugPrint('[LocalNotif] Click payload: ${details.payload}');
        },
      );

      // Solicitar permisos de notificación (iOS/Android 13+)
      await requestNotificationPermissions();

      // Handlers FCM
      fcm.FirebaseMessaging.onMessage.listen((fcm.RemoteMessage message) async {
        if (kDebugMode) debugPrint('[FCM] Foreground: ${message.notification?.title}');
        await _showLocalNotificationFromMessage(message);
      });

      fcm.FirebaseMessaging.onMessageOpenedApp.listen((fcm.RemoteMessage message) {
        if (kDebugMode) debugPrint('[FCM] OpenedApp: ${message.notification?.title}');
        // Integración con navegación: manejar deep link desde message.data
      });

      final initial = await _messaging?.getInitialMessage();
      if (initial != null) {
        if (kDebugMode) debugPrint('[FCM] InitialMessage: ${initial.notification?.title}');
        // Manejar navegación inicial según payload
      }

      // Escuchar refresh de token y guardarlo para el usuario actual
      _messaging?.onTokenRefresh.listen((newToken) async {
        final uid = _auth?.currentUser?.uid;
        if (uid != null) {
          await saveDeviceToken(userId: uid);
          if (kDebugMode) debugPrint('[FCM] Token refrescado y guardado');
        }
      });

      // In-App Messaging: no habilitado (el paquete no está presente)
    } catch (e) {
      debugPrint('[Messaging] Error configuración: $e');
    }
  }

  /// Solicita permisos de notificación con manejo por plataforma.
  Future<void> requestNotificationPermissions() async {
    try {
      if (_messaging == null) return;
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (kDebugMode) debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('[FCM] Error solicitando permisos: $e');
    }
  }

  /// Envía una notificación usando el Worker de Cloudflare (tokens o topic)
  Future<bool> sendNotificationViaWorker({
    List<String>? tokens,
    String? topic,
    required String title,
    required String body,
    String? image,
    Map<String, Object>? data,
  }) async {
    try {
      final endpoint = env.Environment.FCM_WORKER_ENDPOINT;
      final payload = <String, Object?>{
        if (tokens != null) 'tokens': tokens,
        if (topic != null) 'topic': topic,
        'title': title,
        'body': body,
        if (image != null) 'image': image,
        if (data != null) 'data': data,
      };
      final resp = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) return true;
      debugPrint('[Worker] Error ${resp.statusCode}: ${resp.body}');
      return false;
    } catch (e) {
      debugPrint('[Worker] Error enviando notificación: $e');
      return false;
    }
  }

  /// Obtiene el token de dispositivo para FCM.
  Future<String?> getDeviceToken() async {
    try {
      if (kIsWeb) {
        return await _messaging?.getToken(vapidKey: env.Environment.FIREBASE_WEB_VAPID_KEY);
      }
      return await _messaging?.getToken();
    } catch (e) {
      debugPrint('[FCM] Error obteniendo token: $e');
      return null;
    }
  }

  /// Suscribe el dispositivo a un tópico.
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging?.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('[FCM] Error suscribiendo a $topic: $e');
    }
  }

  /// Cancela la suscripción del dispositivo a un tópico.
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('[FCM] Error desuscribiendo de $topic: $e');
    }
  }

  /// Envía una notificación local simple.
  Future<void> sendLocalNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'memoria_viva_channel',
      'Memoria Viva Notifications',
      channelDescription: 'Canal para notificaciones de Memoria Viva Nicaragua',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iOSDetails);
    await _localNotifications.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  }

  Future<void> _showLocalNotificationFromMessage(fcm.RemoteMessage message) async {
    if (message.notification == null) return;
    final title = message.notification!.title ?? 'Notificación';
    final body = message.notification!.body ?? '';
    await sendLocalNotification(title: title, body: body);
  }

  // ==========================
  // Remote Config
  // ==========================

  /// Configura Remote Config con defaults y fetch/activate, usando intervalos por entorno.
  Future<void> configureRemoteConfig() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: kReleaseMode ? const Duration(hours: 1) : const Duration(seconds: 10),
      ));

      await _remoteConfig!.setDefaults(<String, Object>{
        'feature_trivia_enabled': true,
        'home_banner_text': 'Bienvenido a Memoria Viva',
        'map_markers_limit': 100,
      });

      try {
        final updated = await _remoteConfig!.fetchAndActivate();
        if (kDebugMode) debugPrint('[RemoteConfig] fetchAndActivate updated=$updated');
      } catch (e) {
        debugPrint('[RemoteConfig] Error en fetchAndActivate: $e');
      }
    } catch (e) {
      debugPrint('[RemoteConfig] Error en configuración: $e');
      _remoteConfig = null;
    }
  }

  /// Establece el identificador del usuario para Crashlytics/Analytics y propiedades útiles.
  Future<void> setUserContext({
    required String userId,
    String? userRole,
    Map<String, String>? properties,
  }) async {
    try {
      // Crashlytics user id
      if (_crashlyticsEnabled && !kIsWeb) {
        await FirebaseCrashlytics.instance.setUserIdentifier(userId);
        if (userRole != null) {
          await FirebaseCrashlytics.instance.setCustomKey('user_role', userRole);
        }
        if (properties != null) {
          for (final entry in properties.entries) {
            await FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value);
          }
        }
      }

      // Analytics user id y propiedades
      if (_analyticsEnabled && _analytics != null) {
        await _analytics!.setUserId(id: userId);
        if (userRole != null) {
          await _analytics!.setUserProperty(name: 'role', value: userRole);
        }
        if (properties != null) {
          for (final entry in properties.entries) {
            await _analytics!.setUserProperty(name: entry.key, value: entry.value);
          }
        }
      }
    } catch (e) {
      debugPrint('[UserContext] Error configurando contexto de usuario: $e');
    }
  }
}
