import '../../entities/user.dart';
import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';

/// Caso de uso para iniciar sesión con email y contraseña
class LoginWithEmailUseCase {
  final IUserRepository _userRepository;

  LoginWithEmailUseCase(this._userRepository);

  /// Ejecuta el inicio de sesión
  /// 
  /// Throws:
  /// - [InvalidCredentialsException] si las credenciales son inválidas
  /// - [EmailNotVerifiedException] si el email no está verificado
  /// - [NetworkException] si hay problemas de conexión
  Future<User> execute({
    required String email,
    required String password,
  }) async {
    try {
      return await _userRepository.iniciarSesionEmail(
        email: email,
        password: password,
      );
    } catch (e) {
      if (e.toString().contains('wrong-password')) {
        throw InvalidCredentialsException();
      }
      if (e.toString().contains('user-not-found')) {
        throw UserNotFoundException();
      }
      if (e.toString().contains('network-error')) {
        throw NetworkException();
      }
      throw AuthException('Error al iniciar sesión: $e');
    }
  }
}
