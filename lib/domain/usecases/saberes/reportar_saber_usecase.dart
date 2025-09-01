import '../../entities/relato.dart';
import '../../entities/saber_popular.dart';
import '../../enums/estado_moderacion.dart';
import '../../exceptions/auth_exception.dart';
import '../../exceptions/saber_exception.dart';
import '../../repositories/saber_popular_repository.dart';
import '../../repositories/user_repository.dart';
import '../../aggregates/saber_popular_aggregate.dart';
import '../../events/saber_popular_events.dart';
import '../../policies/moderacion_policy.dart';

/// Caso de uso para reportar un saber popular
class ReportarSaberUseCase {
  final ISaberPopularRepository _saberRepository;
  final IUserRepository _userRepository;

  ReportarSaberUseCase(
    this._saberRepository,
    this._userRepository,
  );

  /// Reporta un saber por contenido inapropiado utilizando el agregado SaberPopularAggregate
  /// y aplicando las políticas de moderación
  /// 
  /// [usuarioId] - ID del usuario que reporta
  /// [saberId] - ID del saber reportado
  /// [razon] - Motivo del reporte
  /// 
  /// Throws:
  /// - [SaberNotFoundException] si el saber no existe
  /// - [SaberAlreadyReportedException] si ya fue reportado por este usuario
  /// - [SaberPermissionException] si el usuario no puede reportar
  /// - [SaberPopularException] para otros errores
  Future<void> execute({
    required String usuarioId,
    required String saberId,
    required String razon,
  }) async {
    try {
      // Verificar que el usuario existe
      final usuario = await _userRepository.obtenerUsuarioPorId(usuarioId);
      if (usuario == null) {
        throw UserNotFoundException.withId(usuarioId);
      }

      // Verificar que el saber existe
      final saber = await _saberRepository.obtenerSaberPorId(saberId);
      if (saber == null) {
        throw SaberNotFoundException();
      }
      
      // Verificar que el usuario puede reportar el contenido
      if (!ModeracionPolicy.puedeReportarContenido(usuario, saber.autorId)) {
        throw SaberPermissionException('No puedes reportar tu propio contenido');
      }
      
      // Obtener comentarios y verificaciones (en una implementación real se obtendrían del repositorio)
      final comentarios = <ComentarioSaber>[];
      final verificaciones = <VerificacionSaber>[];
      
      // Crear el agregado
      final saberAggregate = SaberPopularAggregate(saber, comentarios, verificaciones);
      
      // Aplicar el reporte a través del agregado
      final saberReportado = saberAggregate.reportarSaber(
        reportadorId: usuarioId,
        razon: razon,
      );
      
      // Obtener el saber actualizado
      final saberActualizado = saberReportado.saber;
      
      // Persistir los cambios
      await _saberRepository.actualizarSaber(saberActualizado);
      
      // Obtener eventos generados
      final eventos = saberReportado.obtenerYLimpiarEventos();
      
      // Si alcanza cierto número de reportes, verificar si requiere revisión automática
      if (ModeracionPolicy.requiereRevisionAutomatica(saberActualizado.reportes)) {
        // Cambiar estado a reportado si no está ya moderado
        if (!saberActualizado.procesado) {
          await _saberRepository.moderarSaber(
            saberId,
            EstadoModeracion.reportado,
          );
        }
      }
      
      // TODO: Publicar eventos de dominio
      // for (final evento in eventos) {
      //   eventBus.publish(evento);
      // }
      
      // TODO: Notificar a moderadores
    } catch (e) {
      if (e is UserNotFoundException || 
          e is SaberNotFoundException ||
          e is SaberAlreadyReportedException) {
        rethrow;
      }
      throw SaberPopularException('Error al reportar saber: $e');
    }
  }
}
