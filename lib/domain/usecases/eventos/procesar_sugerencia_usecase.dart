import '../../entities/evento_cultural.dart';
import '../../entities/user.dart';
import '../../enums/roles_usuario.dart';
import '../../exceptions/auth_exception.dart';
import '../../exceptions/evento_exception.dart';
import '../../repositories/evento_cultural_repository.dart';
import '../../repositories/user_repository.dart';
import '../../enums/estado_moderacion.dart';
import '../../enums/tipos_evento.dart';

/// Caso de uso para procesar (aprobar/rechazar) una sugerencia de evento
class ProcesarSugerenciaUseCase {
  final IEventoCulturalRepository _eventoRepository;
  final IUserRepository _userRepository;

  ProcesarSugerenciaUseCase(
    this._eventoRepository,
    this._userRepository,
  );

  /// Procesa una sugerencia de evento
  /// 
  /// [adminId] - ID del administrador que procesa
  /// [sugerenciaId] - ID de la sugerencia
  /// [aprobar] - true para aprobar, false para rechazar
  /// [razonRechazo] - Razón si se rechaza
  /// 
  /// Throws:
  /// - [SugerenciaNotFoundException] si la sugerencia no existe
  /// - [EventoPermissionException] si no es admin
  /// - [SugerenciaProcessException] si ya fue procesada
  /// - [EventoException] para otros errores
  Future<void> execute({
    required String adminId,
    required String sugerenciaId,
    required bool aprobar,
    String? razonRechazo,
  }) async {
    try {
      // Verificar que es admin
      final admin = await _userRepository.obtenerUsuarioPorId(adminId);
      if (admin?.rol != UserRole.admin) {
        throw EventoPermissionException(
          'Solo los administradores pueden procesar sugerencias'
        );
      }

      // Obtener la sugerencia
      final sugerencia = await _eventoRepository.obtenerSugerenciaPorId(sugerenciaId);
      if (sugerencia == null) {
        throw SugerenciaNotFoundException();
      }

      // Verificar que no esté ya procesada
      if (sugerencia.estado != EstadoSugerencia.pendiente) {
        throw SugerenciaProcessException(
          'La sugerencia ya fue procesada anteriormente'
        );
      }

      if (aprobar) {
        // Crear el evento oficial
        final evento = EventoCultural.crear(
          nombre: sugerencia.nombre,
          descripcion: sugerencia.descripcion,
          categoriaId: sugerencia.categoriaId,
          categoriaNombre: sugerencia.categoriaNombre,
          tipo: sugerencia.tipo,
          ubicacion: sugerencia.ubicacion,
          fechaInicio: sugerencia.fechaInicio,
          fechaFin: sugerencia.fechaFin,
          esRecurrente: sugerencia.esRecurrente,
          frecuencia: sugerencia.frecuencia,
          organizador: sugerencia.organizador,
          contacto: sugerencia.contacto,
          imagenes: sugerencia.imagenes,
          creadoPorId: adminId,
        );

        // Guardar evento y actualizar sugerencia
        await _eventoRepository.guardarEvento(evento);
        await _eventoRepository.aprobarSugerencia(
          sugerenciaId: sugerenciaId,
          adminId: adminId,
        );

        // TODO: Notificar al usuario que su sugerencia fue aprobada
      } else {
        // Verificar razón de rechazo
        if (razonRechazo?.trim().isEmpty ?? true) {
          throw EventoInvalidContentException(
            'Debe proporcionar una razón para rechazar la sugerencia'
          );
        }

        // Rechazar sugerencia
        await _eventoRepository.rechazarSugerencia(
          sugerenciaId: sugerenciaId,
          razon: razonRechazo!,
          adminId: adminId,
        );

        // TODO: Notificar al usuario que su sugerencia fue rechazada
      }
    } catch (e) {
      if (e is SugerenciaNotFoundException ||
          e is EventoPermissionException ||
          e is SugerenciaProcessException ||
          e is EventoInvalidContentException) {
        rethrow;
      }
      throw EventoException('Error al procesar sugerencia: $e');
    }
  }
}