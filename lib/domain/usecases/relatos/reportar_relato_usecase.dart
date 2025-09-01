import 'package:memoria_viva_nicaragua/domain/enums/estado_moderacion.dart';

import '../../entities/relato.dart';
import '../../exceptions/auth_exception.dart';
import '../../exceptions/relato_exception.dart';
import '../../repositories/relato_repository.dart';
import '../../repositories/user_repository.dart';

/// Caso de uso para reportar un relato
class ReportarRelatoUseCase {
  final IRelatoRepository _relatoRepository;
  final IUserRepository _userRepository;

  ReportarRelatoUseCase(
    this._relatoRepository,
    this._userRepository,
  );

  /// Reporta un relato por contenido inapropiado
  /// 
  /// [usuarioId] - ID del usuario que reporta
  /// [relatoId] - ID del relato reportado
  /// [razon] - Motivo del reporte
  /// 
  /// Throws:
  /// - [RelatoNotFoundException] si el relato no existe
  /// - [RelatoAlreadyReportedException] si ya fue reportado por este usuario
  /// - [RelatoException] para otros errores
  Future<void> execute({
    required String usuarioId,
    required String relatoId,
    required String razon,
  }) async {
    try {
      // Verificar que el usuario existe
      final usuario = await _userRepository.obtenerUsuarioPorId(usuarioId);
      if (usuario == null) {
        throw UserNotFoundException();
      }

      // Verificar que el relato existe
      final relato = await _relatoRepository.obtenerRelatoPorId(relatoId);
      if (relato == null) {
        throw RelatoNotFoundException();
      }

      // Reportar el relato
      await _relatoRepository.reportarRelato(relatoId, razon);

      // Si alcanza cierto número de reportes, cambiar estado
      if (relato.reportes >= 4) { // 5 reportes incluyendo este
        await _relatoRepository.moderarRelato(
          relatoId,
          EstadoModeracion.reportado,
        );
      }

      // TODO: Notificar a moderadores
    } catch (e) {
      if (e is UserNotFoundException || 
          e is RelatoNotFoundException ||
          e is RelatoAlreadyReportedException) {
        rethrow;
      }
      throw RelatoException('Error al reportar relato: $e');
    }
  }
}
