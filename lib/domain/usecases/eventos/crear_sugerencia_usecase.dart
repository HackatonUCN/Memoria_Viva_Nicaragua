import '../../entities/evento_cultural.dart';

import '../../enums/roles_usuario.dart';
import '../../exceptions/auth_exception.dart';
import '../../exceptions/evento_exception.dart';
import '../../exceptions/categoria_exception.dart';
import '../../repositories/evento_cultural_repository.dart';
import '../../repositories/categoria_repository.dart';
import '../../repositories/user_repository.dart';
import '../../validators/contenido_validator.dart';
import '../../value_objects/ubicacion.dart';
import '../../value_objects/multimedia.dart';
import '../../enums/tipos_evento.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para crear una sugerencia de evento
class CrearSugerenciaUseCase {
  final IEventoCulturalRepository _eventoRepository;
  final ICategoriaRepository _categoriaRepository;
  final IUserRepository _userRepository;
  final ContenidoValidator _validator;

  CrearSugerenciaUseCase(
    this._eventoRepository,
    this._categoriaRepository,
    this._userRepository,
    this._validator,
  );

  /// Crea una nueva sugerencia de evento
  /// 
  /// Throws:
  /// - [EventoInvalidContentException] si el contenido es inválido
  /// - [EventoInvalidDateException] si las fechas son inválidas
  /// - [CategoriaNotFoundException] si la categoría no existe
  /// - [UserNotFoundException] si el usuario no existe
  /// - [EventoException] para otros errores
  UseCaseResult<SugerenciaEvento> execute({
    required String usuarioId,
    required String nombre,
    required String descripcion,
    required String categoriaId,
    required TipoEvento tipo,
    required String departamento,
    required String municipio,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String organizador,
    String? contacto,
    bool esRecurrente = false,
    String? frecuencia,
    double? latitud,
    double? longitud,
    List<String> imagenesUrls = const [],
  }) async {
    try {
      // Validar usuario
      final usuario = await _userRepository.obtenerUsuarioPorId(usuarioId);
      if (usuario == null) {
        throw UserNotFoundException.withId(usuarioId);
      }

      // Validar que no sea usuario invitado
      if (usuario.rol == UserRole.invitado) {
        throw EventoPermissionException(
          'Los usuarios invitados no pueden sugerir eventos'
        );
      }

      // Validar categoría
      final categoria = await _categoriaRepository.obtenerCategoriaPorId(categoriaId);
      if (categoria == null) {
        throw CategoriaNotFoundException.withId(categoriaId);
      }

      // Validar contenido
      if (nombre.trim().isEmpty || descripcion.trim().isEmpty) {
        throw EventoInvalidContentException.fromValidation(
          'El nombre y descripción son obligatorios'
        );
      }

      // Validar fechas
      if (fechaInicio.isAfter(fechaFin)) {
        throw EventoInvalidDateException.fechaInicioMayorQueFin();
      }

      // Crear ubicación
      Ubicacion ubicacion;
      try {
        ubicacion = Ubicacion(
          latitud: latitud ?? 0,
          longitud: longitud ?? 0,
          departamento: departamento,
          municipio: municipio,
        );
      } catch (e) {
        throw EventoLocationException.fromError(e.toString());
      }

      // Convertir URLs de imágenes a objetos Multimedia
      final List<Multimedia> imagenes = [];
      for (final url in imagenesUrls) {
        try {
          imagenes.add(Multimedia(
            url: url,
            tipo: TipoMultimedia.imagen,
          ));
        } catch (e) {
          throw EventoMediaException.formatoInvalido(url);
        }
      }

      // Crear la sugerencia
      final sugerencia = SugerenciaEvento.crear(
        nombre: nombre,
        descripcion: descripcion,
        categoriaId: categoriaId,
        categoriaNombre: categoria.nombre,
        tipo: tipo,
        ubicacion: ubicacion,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        esRecurrente: esRecurrente,
        frecuencia: frecuencia,
        organizador: organizador,
        contacto: contacto,
        imagenes: imagenes,
        sugeridoPorId: usuarioId,
        sugeridoPorNombre: usuario.nombre,
      );

      // Guardar la sugerencia
      await _eventoRepository.guardarSugerencia(sugerencia);

      return Success<SugerenciaEvento, Failure>(sugerencia);
    } catch (e) {
      return FailureResult<SugerenciaEvento, Failure>(mapExceptionToFailure(e));
    }
  }
}