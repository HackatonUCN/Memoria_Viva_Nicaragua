enum ConnectivityType { none, wifi, mobile, ethernet, other }

class ConnectivityState {
  final bool online;
  final ConnectivityType type;
  final DateTime at;
  ConnectivityState({required this.online, required this.type, DateTime? at}) : at = at ?? DateTime.now();
}

abstract class IConnectivityService {
  /// Último estado conocido
  ConnectivityState get current;

  /// Notificaciones de cambios de conectividad
  Stream<ConnectivityState> get changes;

  /// Ping activo a un endpoint para validar salida a internet
  Future<bool> ping({Duration timeout = const Duration(seconds: 2)});
}


