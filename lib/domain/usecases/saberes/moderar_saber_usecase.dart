import '../../enums/roles_usuario.dart';
import '../../exceptions/auth_exception.dart';
import '../../exceptions/saber_exception.dart';
import '../../repositories/saber_popular_repository.dart';
import '../../repositories/user_repository.dart';
import '../../aggregates/saber_popular_aggregate.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para moderar un saber popular
class ModerarSaberUseCase {
  final ISaberPopularRepository _saberRepository;
  final IUserRepository _userRepository;

  ModerarSaberUseCase(
    this._saberRepository,
    this._userRepository,
  );

  /// Modera un saber popular (aprobar/ocultar) utilizando el agregado SaberPopularAggregate
  /// 
  /// [adminId] - ID del administrador que modera
  /// [saberId] - ID del saber a moderar
  /// [aprobar] - Si el saber debe ser aprobado o rechazado
  /// [razon] - Razón opcional de la moderación
  /// 
  /// Throws:
  /// - [SaberNotFoundException] si el saber no existe
  /// - [SaberPermissionException] si no es admin
  /// - [SaberException] para otros errores
  UseCaseResult<void> execute({
    required String adminId,
    required String saberId,
    required bool aprobar,
    String? razon,
  }) async {
    try {
      // Verificar que es admin o moderador
      final admin = await _userRepository.obtenerUsuarioPorId(adminId);
      if (admin == null) {
        throw UserNotFoundException.withId(adminId);
      }
      
      if (admin.rol != UserRole.admin) {
        throw SaberPermissionException(
          'Solo los administradores pueden moderar saberes'
        );
      }

      // Verificar que el saber existe
      final saber = await _saberRepository.obtenerSaberPorId(saberId);
      if (saber == null) {
        throw SaberNotFoundException();
      }
      
      // Obtener comentarios y verificaciones (en una implementación real se obtendrían del repositorio)
      final comentarios = <ComentarioSaber>[];
      final verificaciones = <VerificacionSaber>[];
      
      // Crear el agregado
      final saberAggregate = SaberPopularAggregate(saber, comentarios, verificaciones);
      
      // Aplicar la moderación a través del agregado
      final saberModerado = saberAggregate.moderarSaber(
        moderadorId: adminId,
        aprobar: aprobar,
        razon: razon,
      );
      
      // Obtener el saber actualizado
      final saberActualizado = saberModerado.saber;
      
      // Persistir los cambios
      await _saberRepository.actualizarSaber(saberActualizado);
      
      // Obtener eventos generados
      final eventos = saberModerado.obtenerYLimpiarEventos();
      
      // TODO: Publicar eventos de dominio
      // for (final evento in eventos) {
      //   eventBus.publish(evento);
      // }
      
      // TODO: Enviar notificación al autor
      return Success<void, Failure>(null);
    } catch (e) {
      return FailureResult<void, Failure>(mapExceptionToFailure(e));
    }
  }
}