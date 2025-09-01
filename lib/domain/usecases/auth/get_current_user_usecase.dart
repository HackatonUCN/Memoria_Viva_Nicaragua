import '../../entities/user.dart';
import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para obtener el usuario actual
class GetCurrentUserUseCase {
  final IUserRepository _userRepository;

  GetCurrentUserUseCase(this._userRepository);

  /// Obtiene el usuario actualmente autenticado
  /// 
  /// Returns null si no hay usuario autenticado
  /// 
  /// Throws:
  /// - [AuthException] si hay algún error durante el proceso
  UseCaseResult<User?> execute() async {
    try {
      final user = await _userRepository.obtenerUsuarioActual();
      return Success<User?, Failure>(user);
    } catch (e) {
      return FailureResult<User?, Failure>(mapExceptionToFailure(AuthException('Error al obtener usuario actual: $e')));
    }
  }

  /// Stream que emite cambios en el usuario actual
  Stream<User?> observe() {
    return _userRepository.observarUsuarioActual();
  }
}
