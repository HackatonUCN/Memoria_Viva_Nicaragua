import '../../enums/roles_usuario.dart';
import '../../exceptions/evento_exception.dart';
import '../../repositories/evento_cultural_repository.dart';
import '../../repositories/user_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para restaurar un evento cultural eliminado
class RestaurarEventoUseCase {
  final IEventoCulturalRepository _eventoRepository;
  final IUserRepository _userRepository;

  RestaurarEventoUseCase(
    this._eventoRepository,
    this._userRepository,
  );

  /// Restaura un evento cultural previamente eliminado
  /// 
  /// [adminId] - ID del administrador que restaura
  /// [eventoId] - ID del evento a restaurar
  /// 
  /// Throws:
  /// - [EventoNotFoundException] si el evento no existe
  /// - [EventoPermissionException] si no es admin
  /// - [EventoNotDeletedException] si el evento no está eliminado
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
          'Solo los administradores pueden restaurar eventos'
        );
      }

      // Verificar que el evento existe
      final evento = await _eventoRepository.obtenerEventoPorId(eventoId);
      if (evento == null) {
        throw EventoNotFoundException();
      }

      // Verificar que esté eliminado
      if (!evento.eliminado) {
        throw EventoNotDeletedException();
      }

      // Restaurar el evento
      await _eventoRepository.restaurarEvento(eventoId);
      return Success<void, Failure>(null);
    } catch (e) {
      return FailureResult<void, Failure>(mapExceptionToFailure(e));
    }
  }
}
