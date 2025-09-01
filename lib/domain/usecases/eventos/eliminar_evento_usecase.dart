import '../../entities/user.dart';
import '../../enums/roles_usuario.dart';
import '../../exceptions/auth_exception.dart';
import '../../exceptions/evento_exception.dart';
import '../../repositories/evento_cultural_repository.dart';
import '../../repositories/user_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para eliminar un evento cultural (soft delete)
class EliminarEventoUseCase {
  final IEventoCulturalRepository _eventoRepository;
  final IUserRepository _userRepository;

  EliminarEventoUseCase(
    this._eventoRepository,
    this._userRepository,
  );

  /// Elimina un evento cultural (soft delete)
  /// 
  /// [adminId] - ID del administrador que elimina
  /// [eventoId] - ID del evento a eliminar
  /// 
  /// Throws:
  /// - [EventoNotFoundException] si el evento no existe
  /// - [EventoPermissionException] si no es admin
  /// - [EventoAlreadyDeletedException] si ya está eliminado
  /// - [EventoException] para otros errores
  UseCaseResult<void> execute({
    required String adminId,
    required String eventoId,
  }) async {
    try {
      // Verificar que es admin
      final admin = await _userRepository.obtenerUsuarioPorId(adminId);
      if (admin?.rol != UserRole.admin) {
        throw EventoPermissionException(
          'Solo los administradores pueden eliminar eventos'
        );
      }

      // Verificar que el evento existe
      final evento = await _eventoRepository.obtenerEventoPorId(eventoId);
      if (evento == null) {
        throw EventoNotFoundException();
      }

      // Verificar que no esté ya eliminado
      if (evento.eliminado) {
        throw EventoAlreadyDeletedException();
      }

      // Eliminar el evento (soft delete)
      await _eventoRepository.eliminarEvento(eventoId);
      return Success<void, Failure>(null);
    } catch (e) {
      return FailureResult<void, Failure>(mapExceptionToFailure(e));
    }
  }
}