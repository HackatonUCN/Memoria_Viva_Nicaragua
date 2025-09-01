import '../../entities/user.dart';
import '../../entities/saber_popular.dart';
import '../../enums/roles_usuario.dart';
import '../../exceptions/auth_exception.dart';
import '../../exceptions/saber_exception.dart';
import '../../repositories/saber_popular_repository.dart';
import '../../repositories/user_repository.dart';
import '../../aggregates/saber_popular_aggregate.dart';
import '../../events/saber_popular_events.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para eliminar un saber popular (soft delete)
class EliminarSaberUseCase {
  final ISaberPopularRepository _saberRepository;
  final IUserRepository _userRepository;

  EliminarSaberUseCase(
    this._saberRepository,
    this._userRepository,
  );

  /// Elimina un saber popular (soft delete) utilizando el agregado SaberPopularAggregate
  /// 
  /// [usuarioId] - ID del usuario que intenta eliminar
  /// [saberId] - ID del saber a eliminar
  /// 
  /// Throws:
  /// - [SaberNotFoundException] si el saber no existe
  /// - [SaberPermissionException] si no tiene permisos
  /// - [SaberAlreadyDeletedException] si ya está eliminado
  /// - [SaberException] para otros errores
  UseCaseResult<void> execute({
    required String usuarioId,
    required String saberId,
  }) async {
    try {
      // Verificar que el saber existe
      final saber = await _saberRepository.obtenerSaberPorId(saberId);
      if (saber == null) {
        throw SaberNotFoundException();
      }

      // Verificar que no esté ya eliminado
      if (saber.eliminado) {
        throw SaberAlreadyDeletedException();
      }

      // Verificar permisos
      final usuario = await _userRepository.obtenerUsuarioPorId(usuarioId);
      if (usuario == null) {
        throw UserNotFoundException();
      }

      // Solo el autor o un admin pueden eliminar
      if (saber.autorId != usuarioId && usuario.rol != UserRole.admin) {
        throw SaberPermissionException(
          'Solo el autor o un administrador pueden eliminar este saber'
        );
      }

      // Obtener comentarios y verificaciones (en una implementación real se obtendrían del repositorio)
      final comentarios = <ComentarioSaber>[];
      final verificaciones = <VerificacionSaber>[];
      
      // Crear el agregado
      final saberAggregate = SaberPopularAggregate(saber, comentarios, verificaciones);
      
      // Eliminar el saber a través del agregado
      final saberEliminado = saberAggregate.eliminarSaber(
        usuarioId: usuarioId,
      );
      
      // Obtener el saber actualizado
      final saberActualizado = saberEliminado.saber;
      
      // Obtener eventos generados
      final eventos = saberEliminado.obtenerYLimpiarEventos();
      
      // Persistir los cambios (soft delete)
      await _saberRepository.actualizarSaber(saberActualizado);
      
      // TODO: Publicar eventos de dominio
      // for (final evento in eventos) {
      //   eventBus.publish(evento);
      // }
      
      // Actualizar estadísticas del autor
      final autor = await _userRepository.obtenerUsuarioPorId(saber.autorId);
      if (autor != null) {
        await _userRepository.actualizarEstadisticas(
          userId: saber.autorId,
          saberesCompartidos: autor.saberesCompartidos - 1,
        );
      }
      return Success<void, Failure>(null);
    } catch (e) {
      return FailureResult<void, Failure>(mapExceptionToFailure(e));
    }
  }
}