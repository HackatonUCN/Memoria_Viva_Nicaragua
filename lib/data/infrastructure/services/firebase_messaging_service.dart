import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Stream para escuchar mensajes cuando la app está en primer plano
  final StreamController<RemoteMessage> _messageStreamController = StreamController.broadcast();
  Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

  Future<void> initialize() async {
    try {
      // Solicitar permisos para notificaciones
      await _requestPermissions();
      
      // Configurar notificaciones locales
       await _initializeLocalNotifications();
      
      // Configurar handlers para diferentes estados de la app
      _setupForegroundHandler();
      _setupBackgroundHandler();
      _setupTerminatedHandler();
      
      // Obtener el token FCM
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
    } catch (e) {
      print('Error inicializando Firebase Messaging: $e');
      if (kIsWeb) {
        print('Firebase Messaging puede no funcionar correctamente en la web');
      }
    }
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('Notification permission status: ${settings.authorizationStatus}');
  }

   Future<void> _initializeLocalNotifications() async {
     const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings();
    
   const InitializationSettings initSettings = InitializationSettings(
       android: androidSettings,
       iOS: iOSSettings,
     );

  await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Manejar la interacción con la notificación
         print('Notification clicked: ${details.payload}');
       },
    );
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
      _messageStreamController.add(message);
    });
  }

  void _setupBackgroundHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background state with message: ${message.notification?.title}');
      _messageStreamController.add(message);
    });
  }

  Future<void> _setupTerminatedHandler() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state with message: ${initialMessage.notification?.title}');
      _messageStreamController.add(initialMessage);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (message.notification == null) return;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
     'memoria_viva_channel',
     'Memoria Viva Notifications',
    channelDescription: 'Canal para notificaciones de Memoria Viva Nicaragua',
   importance: Importance.max,
     priority: Priority.high,
    );

    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

     final NotificationDetails notificationDetails = NotificationDetails(
       android: androidDetails,
       iOS: iOSDetails,
     );

     await _localNotifications.show(
       message.hashCode,
       message.notification!.title,
      message.notification!.body,
       notificationDetails,
      payload: message.data.toString(),
     );
   }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  void dispose() {
    _messageStreamController.close();
  }
}
