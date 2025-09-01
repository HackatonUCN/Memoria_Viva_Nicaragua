import '../../entities/user.dart';
import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para iniciar sesión con Google
class LoginWithGoogleUseCase {
  final IUserRepository _userRepository;

  LoginWithGoogleUseCase(this._userRepository);

  /// Ejecuta el inicio de sesión con Google
  /// 
  /// Throws:
  /// - [AuthException] si hay algún error durante el proceso
  /// - [NetworkException] si hay problemas de conexión
  UseCaseResult<User> execute() async {
    try {
      final user = await _userRepository.iniciarSesionGoogle();
      return Success<User, Failure>(user);
    } catch (e) {
      if (e.toString().contains('network-error')) {
        return FailureResult<User, Failure>(mapExceptionToFailure(NetworkException()));
      }
      if (e.toString().contains('cancelled')) {
        return FailureResult<User, Failure>(mapExceptionToFailure(AuthException('Inicio de sesión cancelado por el usuario')));
      }
      return FailureResult<User, Failure>(mapExceptionToFailure(AuthException('Error al iniciar sesión con Google: $e')));
    }
  }
}
