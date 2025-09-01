
import '../../entities/relato.dart';
import '../../entities/user.dart';
import '../../enums/roles_usuario.dart';
import '../../exceptions/auth_exception.dart';
import '../../exceptions/relato_exception.dart';
import '../../exceptions/categoria_exception.dart';
import '../../repositories/relato_repository.dart';
import '../../repositories/categoria_repository.dart';
import '../../repositories/user_repository.dart';
import '../../validators/contenido_validator.dart';
import '../../value_objects/ubicacion.dart';
import '../../value_objects/multimedia.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para crear un nuevo relato
class CrearRelatoUseCase {
  final IRelatoRepository _relatoRepository;
  final ICategoriaRepository _categoriaRepository;
  final IUserRepository _userRepository;
  final ContenidoValidator _validator;

  CrearRelatoUseCase(
    this._relatoRepository,
    this._categoriaRepository,
    this._userRepository,
    this._validator,
  );

  /// Crea un nuevo relato
  /// 
  /// Throws:
  /// - [RelatoInvalidContentException] si el contenido es inválido
  /// - [RelatoMediaException] si hay error con los archivos multimedia
  /// - [RelatoLocationException] si hay error con la ubicación
  /// - [CategoriaNotFoundException] si la categoría no existe
  /// - [UserNotFoundException] si el usuario no existe
  /// - [RelatoException] para otros errores
  UseCaseResult<Relato> execute({
    required String titulo,
    required String contenido,
    required String autorId,
    required String categoriaId,
    String? departamento,
    String? municipio,
    double? latitud,
    double? longitud,
    List<String> imagenesUrls = const [],
    String? audioUrl,
    String? videoUrl,
    List<String> etiquetas = const [],
  }) async {
    try {
      // Validar usuario
      final autor = await _userRepository.obtenerUsuarioPorId(autorId);
      if (autor == null) {
        throw UserNotFoundException();
      }

      // Validar que no sea usuario invitado
      if (autor.rol == UserRole.invitado) {
        throw RelatoPermissionException(
          'Los usuarios invitados no pueden crear relatos'
        );
      }

      // Validar categoría
      final categoria = await _categoriaRepository.obtenerCategoriaPorId(categoriaId);
      if (categoria == null) {
        throw CategoriaNotFoundException();
      }

      // Crear ubicación si se proporcionaron coordenadas
      Ubicacion? ubicacion;
      if (departamento != null && municipio != null) {
        try {
          ubicacion = Ubicacion(
            latitud: latitud ?? 0,
            longitud: longitud ?? 0,
            departamento: departamento,
            municipio: municipio,
          );
        } catch (e) {
          throw RelatoLocationException(e.toString());
        }
      }

      // Convertir URLs a objetos Multimedia
      final List<Multimedia> multimedia = [];
      
      // Procesar imágenes
      for (final url in imagenesUrls) {
        try {
          multimedia.add(Multimedia(
            url: url,
            tipo: TipoMultimedia.imagen,
          ));
        } catch (e) {
          throw RelatoMediaException('Error con imagen $url: $e');
        }
      }

      // Procesar audio si existe
      if (audioUrl != null) {
        try {
          multimedia.add(Multimedia(
            url: audioUrl,
            tipo: TipoMultimedia.audio,
          ));
        } catch (e) {
          throw RelatoMediaException('Error con audio $audioUrl: $e');
        }
      }

      // Procesar video si existe
      if (videoUrl != null) {
        try {
          multimedia.add(Multimedia(
            url: videoUrl,
            tipo: TipoMultimedia.video,
          ));
        } catch (e) {
          throw RelatoMediaException('Error con video $videoUrl: $e');
        }
      }

      // Crear el relato
      final relato = Relato.crear(
        titulo: titulo,
        contenido: contenido,
        autorId: autorId,
        autorNombre: autor.nombre,
        categoriaId: categoriaId,
        categoriaNombre: categoria.nombre,
        ubicacion: ubicacion,
        multimedia: multimedia,
        etiquetas: etiquetas,
      );

      // Validar el relato usando el validator
      try {
        _validator.validarRelato(relato);
      } catch (e) {
        if (e is ContenidoValidationException) {
          throw RelatoInvalidContentException(e.message);
        }
        rethrow;
      }

      // Guardar el relato
      await _relatoRepository.guardarRelato(relato);

      // Actualizar estadísticas del usuario
      await _userRepository.actualizarEstadisticas(
        userId: autorId,
        relatosPublicados: autor.relatosPublicados + 1,
      );

      return Success<Relato, Failure>(relato);
    } catch (e) {
      final failure = mapExceptionToFailure(e);
      return FailureResult<Relato, Failure>(failure);
    }
  }
}