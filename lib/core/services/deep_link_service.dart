import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import '../di/service_locator.dart';
import '../../config/app_router.dart';

/// Servicio simple para manejar deep links del esquema memoriaviva://relatos/{id}
class DeepLinkService {
  StreamSubscription? _sub;
  static bool _initialized = false;
  final AppLinks _appLinks = AppLinks();

  void init() {
    if (_initialized) return;
    _initialized = true;

    // En Web no existe stream de enlaces dinámicos; solo procesamos el enlace inicial si aplica
    if (kIsWeb) {
      // Web: no hay stream; opcionalmente podríamos inspeccionar window.location aquí
      return;
    }

    // Enlaces entrantes
    _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen((uri) {
      if (uri == null) return;
      _handleUri(uri);
    }, onError: (e) {
      if (kDebugMode) print('DeepLink error: $e');
    });

    // Enlace inicial
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    }).catchError((e) {
      if (kDebugMode) print('DeepLink initial error: $e');
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  void _handleUri(Uri uri) {
    if (uri.scheme != 'memoriaviva') return;
    if (uri.host == 'relatos' && uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.first;
      // Navegar a Home y abrir overlay de detalle vía evento (placeholder: ruta home)
      AppRouter.navigatorKey.currentState?.pushNamed(AppRoutes.home, arguments: {'relatoId': id});
    }
    if (uri.host == 'map' || uri.host == 'mapa') {
      final relatoId = uri.queryParameters['relatoId'];
      AppRouter.navigatorKey.currentState?.pushNamed(AppRoutes.mapa, arguments: relatoId != null ? {'relatoId': relatoId} : null);
    }
  }
}


