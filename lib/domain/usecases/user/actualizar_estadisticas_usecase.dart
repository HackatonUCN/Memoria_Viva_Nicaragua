import '../../entities/user.dart';
import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';

/// Caso de uso para actualizar las estadísticas de un usuario
class ActualizarEstadisticasUseCase {
  final IUserRepository _userRepository;

  ActualizarEstadisticasUseCase(this._userRepository);

  /// Actualiza las estadísticas del usuario
  /// 
  /// Throws:
  /// - [UserNotFoundException] si el usuario no existe
  /// - [AuthException] si hay algún error durante el proceso
  Future<void> execute({
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
    } catch (e) {
      if (e is UserNotFoundException) {
        rethrow;
      }
      throw AuthException('Error al actualizar estadísticas: $e');
    }
  }
}
