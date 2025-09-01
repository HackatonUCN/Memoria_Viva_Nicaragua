import '../../entities/evento_cultural.dart';
import '../../entities/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../enums/roles_usuario.dart';
import '../../exceptions/auth_exception.dart';
import '../../exceptions/evento_exception.dart';
import '../../exceptions/categoria_exception.dart';
import '../../repositories/evento_cultural_repository.dart';
import '../../repositories/categoria_repository.dart';
import '../../repositories/user_repository.dart';
import '../../enums/tipos_evento.dart';
import '../../value_objects/ubicacion.dart';
import '../../value_objects/multimedia.dart';

/// Caso de uso para actualizar un evento cultural existente (solo admin)
class ActualizarEventoUseCase {
  final IEventoCulturalRepository _eventoRepository;
  final ICategoriaRepository _categoriaRepository;
  final IUserRepository _userRepository;

  ActualizarEventoUseCase(
    this._eventoRepository,
    this._categoriaRepository,
    this._userRepository,
  );

  /// Actualiza un evento cultural existente
  /// 
  /// [adminId] - ID del administrador que actualiza
  /// 
  /// Throws:
  /// - [EventoNotFoundException] si el evento no existe
  /// - [EventoPermissionException] si no es admin
  /// - [EventoInvalidContentException] si el contenido es inválido
  /// - [EventoInvalidDateException] si las fechas son inválidas
  /// - [CategoriaNotFoundException] si la categoría no existe
  /// - [EventoException] para otros errores
  Future<void> execute({
    required String adminId,
    required String eventoId,
    String? nombre,
    String? descripcion,
    String? categoriaId,
    TipoEvento? tipo,
    String? departamento,
    String? municipio,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? organizador,
    String? contacto,
    bool? esRecurrente,
    String? frecuencia,
    double? latitud,
    double? longitud,
    List<String>? imagenesUrls,
  }) async {
    try {
      // Verificar que es admin
      final admin = await _userRepository.obtenerUsuarioPorId(adminId);
      if (admin?.rol != UserRole.admin) {
        throw EventoPermissionException(
          'Solo los administradores pueden actualizar eventos'
        );
      }

      // Obtener el evento
      final evento = await _eventoRepository.obtenerEventoPorId(eventoId);
      if (evento == null) {
        throw EventoNotFoundException();
      }

      // Si se cambia la categoría, validarla
      String nuevaCategoriaId = evento.categoriaId;
      String nuevaCategoriaNombre = evento.categoriaNombre;
      
      if (categoriaId != null && categoriaId != evento.categoriaId) {
        final categoria = await _categoriaRepository.obtenerCategoriaPorId(categoriaId);
        if (categoria == null) {
          throw CategoriaNotFoundException.withId(categoriaId);
        }
        nuevaCategoriaId = categoria.id;
        nuevaCategoriaNombre = categoria.nombre;
      }

      // Validar contenido si se modifica
      if (nombre?.trim().isEmpty == true || descripcion?.trim().isEmpty == true) {
        throw EventoInvalidContentException(
          'El nombre y descripción no pueden estar vacíos'
        );
      }

      // Validar fechas si se modifican
      final nuevaFechaInicio = fechaInicio ?? evento.fechaInicio;
      final nuevaFechaFin = fechaFin ?? evento.fechaFin;
      
      if (nuevaFechaInicio.isAfter(nuevaFechaFin)) {
        throw EventoInvalidDateException.fechaInicioMayorQueFin();
      }

      // Crear ubicación si se modificaron las coordenadas o el departamento/municipio
      Ubicacion? nuevaUbicacion = evento.ubicacion;
      if ((latitud != null && longitud != null) || 
          (departamento != null && municipio != null)) {
        try {
          nuevaUbicacion = Ubicacion(
            latitud: latitud ?? evento.ubicacion.latitud,
            longitud: longitud ?? evento.ubicacion.longitud,
            departamento: departamento ?? evento.ubicacion.departamento,
            municipio: municipio ?? evento.ubicacion.municipio,
          );
        } catch (e) {
          throw EventoLocationException.fromError(e.toString());
        }
      }

      // Procesar imágenes si se proporcionaron nuevas
      List<Multimedia> nuevasImagenes = evento.imagenes;
      if (imagenesUrls != null) {
        nuevasImagenes = [];
        for (final url in imagenesUrls) {
          try {
            nuevasImagenes.add(Multimedia(
              url: url,
              tipo: TipoMultimedia.imagen,
            ));
          } catch (e) {
            throw EventoMediaException.formatoInvalido(url);
          }
        }
      }

      // Actualizar el evento
      final eventoActualizado = EventoCultural(
        id: evento.id,
        nombre: nombre ?? evento.nombre,
        descripcion: descripcion ?? evento.descripcion,
        tipo: tipo ?? evento.tipo,
        categoriaId: nuevaCategoriaId,
        categoriaNombre: nuevaCategoriaNombre,
        ubicacion: nuevaUbicacion,
        imagenes: nuevasImagenes,
        fechaInicio: nuevaFechaInicio,
        fechaFin: nuevaFechaFin,
        esRecurrente: esRecurrente ?? evento.esRecurrente,
        frecuencia: frecuencia ?? evento.frecuencia,
        organizador: organizador ?? evento.organizador,
        contacto: contacto ?? evento.contacto,
        creadoPorId: evento.creadoPorId,
        fechaCreacion: evento.fechaCreacion,
        fechaActualizacion: DateTime.now(),
        eliminado: evento.eliminado,
        fechaEliminacion: evento.fechaEliminacion,
      );

      await _eventoRepository.actualizarEvento(eventoActualizado);
    } catch (e) {
      if (e is EventoNotFoundException ||
          e is EventoPermissionException ||
          e is CategoriaNotFoundException ||
          e is EventoInvalidContentException ||
          e is EventoInvalidDateException ||
          e is EventoLocationException ||
          e is EventoMediaException) {
        rethrow;
      }
      throw EventoException('Error al actualizar evento: $e');
    }
  }
}