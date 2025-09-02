import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para actualizar el perfil del usuario
class ActualizarPerfilUseCase {
  final IUserRepository _userRepository;

  ActualizarPerfilUseCase(this._userRepository);

  /// Actualiza el perfil del usuario
  /// 
  /// Throws:
  /// - [UserNotFoundException] si el usuario no existe
  /// - [AuthException] si hay algún error durante el proceso
  UseCaseResult<void> execute({
    required String userId,
    String? nombre,
    String? avatarUrl,
    String? departamento,
    String? municipio,
    String? biografia,
  }) async {
    try {
      // Verificar si el usuario existe
      final usuario = await _userRepository.obtenerUsuarioPorId(userId);
      if (usuario == null) {
        throw UserNotFoundException();
      }

      await _userRepository.actualizarPerfil(
        userId: userId,
        nombre: nombre,
        avatarUrl: avatarUrl,
        departamento: departamento,
        municipio: municipio,
        biografia: biografia,
      );
      return Success<void, Failure>(null);
    } catch (e) {
      return FailureResult<void, Failure>(mapExceptionToFailure(e));
    }
  }
}
