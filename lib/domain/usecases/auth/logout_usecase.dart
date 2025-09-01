import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para cerrar sesión
class LogoutUseCase {
  final IUserRepository _userRepository;

  LogoutUseCase(this._userRepository);

  /// Cierra la sesión del usuario actual
  /// 
  /// Throws:
  /// - [AuthException] si hay algún error durante el proceso
  UseCaseResult<void> execute() async {
    try {
      await _userRepository.cerrarSesion();
      return Success<void, Failure>(null);
    } catch (e) {
      return FailureResult<void, Failure>(mapExceptionToFailure(AuthException('Error al cerrar sesión: $e')));
    }
  }
}
