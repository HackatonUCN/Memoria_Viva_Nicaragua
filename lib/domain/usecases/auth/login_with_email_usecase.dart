import '../../entities/user.dart';
import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

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
  UseCaseResult<User> execute({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _userRepository.iniciarSesionEmail(
        email: email,
        password: password,
      );
      return Success<User, Failure>(user);
    } catch (e) {
      if (e.toString().contains('wrong-password')) {
        return FailureResult<User, Failure>(mapExceptionToFailure(InvalidCredentialsException()));
      }
      if (e.toString().contains('user-not-found')) {
        return FailureResult<User, Failure>(mapExceptionToFailure(UserNotFoundException()));
      }
      if (e.toString().contains('network-error')) {
        return FailureResult<User, Failure>(mapExceptionToFailure(NetworkException()));
      }
      return FailureResult<User, Failure>(mapExceptionToFailure(AuthException('Error al iniciar sesión: $e')));
    }
  }
}
