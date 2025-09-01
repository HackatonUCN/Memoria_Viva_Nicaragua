import '../entities/notificacion.dart';
import '../entities/user.dart';
import '../enums/roles_usuario.dart';

/// Interfaz para el servicio de notificaciones
abstract class INotificationService {
  /// Envía una notificación inmediata
  Future<void> enviarNotificacion(Notificacion notificacion);

  /// Programa una notificación para una fecha futura
  Future<void> programarNotificacion(
    Notificacion notificacion,
    DateTime fecha,
  );

  /// Cancela una notificación programada
  Future<void> cancelarNotificacion(String notificacionId);

  /// Envía notificación a usuarios cercanos a una ubicación
  Future<void> notificarUsuariosCercanos({
    required double latitud,
    required double longitud,
    required double radioKm,
    required Notificacion notificacion,
  });

  /// Envía notificación a usuarios por rol
  Future<void> notificarPorRol(
    UserRole rol,
    Notificacion notificacion,
  );

  /// Obtiene el token de notificaciones del dispositivo
  Future<String?> obtenerToken();

  /// Solicita permiso para enviar notificaciones
  Future<bool> solicitarPermiso();

  /// Verifica si las notificaciones están habilitadas
  Future<bool> verificarPermisos();

  /// Configura tópicos de notificaciones para el usuario
  Future<void> suscribirTopicos(User usuario);
}
