import '../entities/user.dart';
import '../enums/roles_usuario.dart';

/// Repositorio para manejar los usuarios en la aplicación
abstract class IUserRepository {
  /// Obtiene el usuario actual autenticado
  Future<User?> obtenerUsuarioActual();

  /// Obtiene un usuario por su ID
  Future<User?> obtenerUsuarioPorId(String id);

  /// Obtiene usuarios por rol
  Future<List<User>> obtenerUsuariosPorRol(UserRole rol);

  /// Crea o actualiza un usuario
  Future<void> guardarUsuario(User usuario);

  /// Actualiza el perfil del usuario
  Future<void> actualizarPerfil({
    required String userId,
    String? nombre,
    String? avatarUrl,
    String? departamento,
    String? municipio,
    String? biografia,
  });

  /// Actualiza el rol de un usuario (solo admin)
  Future<void> actualizarRol({
    required String userId,
    required UserRole nuevoRol,
  });

  /// Desactiva una cuenta de usuario
  Future<void> desactivarCuenta(String userId);

  /// Reactiva una cuenta de usuario
  Future<void> reactivarCuenta(String userId);

  /// Actualiza las estadísticas del usuario
  Future<void> actualizarEstadisticas({
    required String userId,
    int? relatosPublicados,
    int? saberesCompartidos,
    int? puntajeTotal,
  });

  /// Actualiza las preferencias de notificaciones
  Future<void> actualizarPreferenciasNotificaciones({
    required String userId,
    required bool notificacionesActivas,
  });

  /// Stream para observar cambios en el usuario actual
  Stream<User?> observarUsuarioActual();

  /// Stream para observar cambios en un usuario específico
  Stream<User?> observarUsuarioPorId(String id);

  /// Busca usuarios por nombre
  Future<List<User>> buscarUsuarios(String texto);

  /// Obtiene las estadísticas de contribución de un usuario
  Future<Map<String, int>> obtenerEstadisticasUsuario(String userId);

  // Métodos de autenticación

  /// Inicia sesión con email y contraseña
  Future<User> iniciarSesionEmail({
    required String email,
    required String password,
  });

  /// Inicia sesión con Google
  Future<User> iniciarSesionGoogle();

  /// Inicia sesión con Apple
  Future<User> iniciarSesionApple();

  /// Registra un nuevo usuario con email
  Future<User> registrarEmail({
    required String email,
    required String password,
    required String nombre,
  });

  /// Cierra la sesión actual
  Future<void> cerrarSesion();

  /// Elimina la cuenta del usuario
  Future<void> eliminarCuenta(String userId);

  /// Envía email de verificación
  Future<void> enviarEmailVerificacion();

  /// Envía email para restablecer contraseña
  Future<void> enviarResetPassword(String email);

  /// Verifica si un email ya está registrado
  Future<bool> verificarEmailExiste(String email);

  /// Actualiza la contraseña del usuario actual
  Future<void> actualizarPassword({
    required String oldPassword,
    required String newPassword,
  });

  /// Vincula una cuenta de Google
  Future<void> vincularGoogle();

  /// Vincula una cuenta de Apple
  Future<void> vincularApple();

  /// Desvincular un proveedor de autenticación
  Future<void> desvincularProveedor(String providerId);
}
