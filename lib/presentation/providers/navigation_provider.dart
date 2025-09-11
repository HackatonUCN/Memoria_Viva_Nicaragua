import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_router.dart';
import 'map_provider.dart';

class NavigationProvider extends ChangeNotifier {
  final GetIt _getIt = GetIt.I;
  int _selectedIndex = 0;
  String _selectedRoute = AppRoutes.home;
  String? _mapFocusRelatoId;

  int get selectedIndex => _selectedIndex;
  String get selectedRoute => _selectedRoute;
  String? get mapFocusRelatoId => _mapFocusRelatoId;

  void setIndex(int index) {
    if (index == _selectedIndex) return;
    _selectedIndex = index;
    _selectedRoute = _routeForIndex(index);
    notifyListeners();
  }

  void setRoute(String route) {
    if (route == _selectedRoute) return;
    _selectedRoute = route;
    _selectedIndex = _indexForRoute(route);
    notifyListeners();
  }

  void setMapFocusRelatoId(String? relatoId) {
    if (relatoId == null) {
      _mapFocusRelatoId = null;
      notifyListeners();
      return;
    }
    
    _mapFocusRelatoId = relatoId;
    notifyListeners();
    
    // Forzar acceso directo al MapProvider si ya existe
    if (_getIt.isRegistered<MapProvider>()) {
      try {
        final mapProvider = _getIt<MapProvider>();
        mapProvider.focusRelatoByIdOrFetch(relatoId);
      } catch (_) {}
    }
  }

  String? takeMapFocusRelatoId() {
    final id = _mapFocusRelatoId;
    _mapFocusRelatoId = null;
    notifyListeners();
    return id;
  }

  String _routeForIndex(int index) {
    switch (index) {
      case 0:
        return AppRoutes.home;
      case 1:
        return AppRoutes.mapa;
      case 2:
        return AppRoutes.publicar;
      case 3:
        return AppRoutes.eventos;
      case 4:
        return AppRoutes.biblioteca;
      default:
        return AppRoutes.home;
    }
  }

  int _indexForRoute(String route) {
    switch (route) {
      case AppRoutes.home:
        return 0;
      case AppRoutes.mapa:
        return 1;
      case AppRoutes.publicar:
        return 2;
      case AppRoutes.eventos:
        return 3;
      case AppRoutes.biblioteca:
        return 4;
      default:
        return _selectedIndex;
    }
  }
}


