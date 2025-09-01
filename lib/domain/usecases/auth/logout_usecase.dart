import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';

/// Caso de uso para cerrar sesión
class LogoutUseCase {
  final IUserRepository _userRepository;

  LogoutUseCase(this._userRepository);

  /// Cierra la sesión del usuario actual
  /// 
  /// Throws:
  /// - [AuthException] si hay algún error durante el proceso
  Future<void> execute() async {
    try {
      await _userRepository.cerrarSesion();
    } catch (e) {
      throw AuthException('Error al cerrar sesión: $e');
    }
  }
}
