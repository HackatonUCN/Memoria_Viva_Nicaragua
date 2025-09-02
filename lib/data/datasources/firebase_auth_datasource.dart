
import '../../domain/entities/user.dart' as domain;

/// Interfaz para la fuente de datos de autenticación con Firebase
abstract class FirebaseAuthDataSource {
  /// Obtiene el usuario actualmente autenticado
  domain.User? getCurrentUser();

  /// Stream para escuchar los cambios en el estado de autenticación
  Stream<domain.User?> get authStateChanges;

  /// Inicia sesión con correo y contraseña
  Future<domain.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Registra un nuevo usuario con correo y contraseña
  Future<domain.User> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// Inicia sesión con Google
  Future<domain.User> signInWithGoogle();

  /// Inicia sesión como invitado (anónimo)
  Future<domain.User> signInAnonymously();

  /// Cierra la sesión del usuario actual
  Future<void> signOut();

  /// Envía un correo electrónico para restablecer la contraseña
  Future<void> resetPassword(String email);

  /// Verifica si el usuario actual es anónimo
  bool isAnonymous();

  /// Verifica si hay un usuario autenticado
  bool isAuthenticated();

  /// Obtiene el token de ID del usuario actual
  Future<String?> getIdToken();
}
