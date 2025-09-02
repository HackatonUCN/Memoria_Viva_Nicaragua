import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para actualizar las estadísticas de un usuario
class ActualizarEstadisticasUseCase {
  final IUserRepository _userRepository;

  ActualizarEstadisticasUseCase(this._userRepository);

  /// Actualiza las estadísticas del usuario
  /// 
  /// Throws:
  /// - [UserNotFoundException] si el usuario no existe
  /// - [AuthException] si hay algún error durante el proceso
  UseCaseResult<void> execute({
    required String userId,
    int? relatosPublicados,
    int? saberesCompartidos,
    int? puntajeTotal,
  }) async {
    try {
      // Verificar si el usuario existe
      final usuario = await _userRepository.obtenerUsuarioPorId(userId);
      if (usuario == null) {
        throw UserNotFoundException();
      }

      await _userRepository.actualizarEstadisticas(
        userId: userId,
        relatosPublicados: relatosPublicados,
        saberesCompartidos: saberesCompartidos,
        puntajeTotal: puntajeTotal,
      );
      return Success<void, Failure>(null);
    } catch (e) {
      return FailureResult<void, Failure>(mapExceptionToFailure(e));
    }
  }
}
