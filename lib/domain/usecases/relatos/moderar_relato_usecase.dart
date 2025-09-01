import '../../entities/user.dart';
import '../../enums/roles_usuario.dart';
import '../../exceptions/relato_exception.dart';
import '../../repositories/relato_repository.dart';
import '../../repositories/user_repository.dart';
import '../../enums/estado_moderacion.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para moderar un relato
class ModerarRelatoUseCase {
  final IRelatoRepository _relatoRepository;
  final IUserRepository _userRepository;

  ModerarRelatoUseCase(
    this._relatoRepository,
    this._userRepository,
  );

  /// Modera un relato (aprobar/ocultar)
  /// 
  /// [adminId] - ID del administrador que modera
  /// [relatoId] - ID del relato a moderar
  /// [estado] - Nuevo estado del relato
  /// 
  /// Throws:
  /// - [RelatoNotFoundException] si el relato no existe
  /// - [RelatoPermissionException] si no es admin
  /// - [RelatoException] para otros errores
  UseCaseResult<void> execute({
    required String adminId,
    required String relatoId,
    required EstadoModeracion estado,
  }) async {
    try {
      // Verificar que es admin
      final admin = await _userRepository.obtenerUsuarioPorId(adminId);
      if (admin?.rol != UserRole.admin) {
        throw RelatoPermissionException(
          'Solo los administradores pueden moderar relatos'
        );
      }

      // Verificar que el relato existe
      final relato = await _relatoRepository.obtenerRelatoPorId(relatoId);
      if (relato == null) {
        throw RelatoNotFoundException();
      }

      // Aplicar moderación
      await _relatoRepository.moderarRelato(relatoId, estado);

      // TODO: Enviar notificación al autor
      return Success<void, Failure>(null);
    } catch (e) {
      final failure = mapExceptionToFailure(e);
      return FailureResult<void, Failure>(failure);
    }
  }
}