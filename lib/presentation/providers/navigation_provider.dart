import 'package:flutter/material.dart';
import '../../config/app_router.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  String _selectedRoute = AppRoutes.home;

  int get selectedIndex => _selectedIndex;
  String get selectedRoute => _selectedRoute;

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


