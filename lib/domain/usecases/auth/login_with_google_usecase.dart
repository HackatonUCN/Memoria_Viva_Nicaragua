import '../../entities/user.dart';
import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';

/// Caso de uso para iniciar sesión con Google
class LoginWithGoogleUseCase {
  final IUserRepository _userRepository;

  LoginWithGoogleUseCase(this._userRepository);

  /// Ejecuta el inicio de sesión con Google
  /// 
  /// Throws:
  /// - [AuthException] si hay algún error durante el proceso
  /// - [NetworkException] si hay problemas de conexión
  Future<User> execute() async {
    try {
      return await _userRepository.iniciarSesionGoogle();
    } catch (e) {
      if (e.toString().contains('network-error')) {
        throw NetworkException();
      }
      if (e.toString().contains('cancelled')) {
        throw AuthException('Inicio de sesión cancelado por el usuario');
      }
      throw AuthException('Error al iniciar sesión con Google: $e');
    }
  }
}
