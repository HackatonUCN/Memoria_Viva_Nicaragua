
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

/// Caso de uso para actualizar un relato existente
class ActualizarRelatoUseCase {
  final IRelatoRepository _relatoRepository;
  final ICategoriaRepository _categoriaRepository;
  final IUserRepository _userRepository;
  final ContenidoValidator _validator;

  ActualizarRelatoUseCase(
    this._relatoRepository,
    this._categoriaRepository,
    this._userRepository,
    this._validator,
  );

  /// Actualiza un relato existente
  /// 
  /// [usuarioId] - ID del usuario que intenta actualizar
  /// 
  /// Throws:
  /// - [RelatoNotFoundException] si el relato no existe
  /// - [RelatoPermissionException] si no tiene permisos
  /// - [RelatoInvalidContentException] si el contenido es inválido
  /// - [CategoriaNotFoundException] si la categoría no existe
  /// - [RelatoException] para otros errores
  UseCaseResult<void> execute({
    required String relatoId,
    required String usuarioId,
    String? titulo,
    String? contenido,
    String? categoriaId,
    String? departamento,
    String? municipio,
    double? latitud,
    double? longitud,
    List<String>? imagenesUrls,
    String? audioUrl,
    String? videoUrl,
    List<String>? etiquetas,
  }) async {
    try {
      // Obtener el relato
      final relato = await _relatoRepository.obtenerRelatoPorId(relatoId);
      if (relato == null) {
        throw RelatoNotFoundException();
      }

      // Verificar permisos
      final usuario = await _userRepository.obtenerUsuarioPorId(usuarioId);
      if (usuario == null) {
        throw UserNotFoundException();
      }

      // Solo el autor o un admin pueden editar
      if (relato.autorId != usuarioId && usuario.rol != UserRole.admin) {
        throw RelatoPermissionException(
          'No tienes permisos para editar este relato'
        );
      }

      // Si se cambia la categoría, validarla
      String nuevaCategoriaId = categoriaId ?? relato.categoriaId;
      String nuevaCategoriaNombre = relato.categoriaNombre;
      
      if (categoriaId != null && categoriaId != relato.categoriaId) {
        final categoria = await _categoriaRepository.obtenerCategoriaPorId(categoriaId);
        if (categoria == null) {
          throw CategoriaNotFoundException();
        }
        nuevaCategoriaNombre = categoria.nombre;
      }

      // Crear ubicación si se proporcionaron nuevas coordenadas
      Ubicacion? nuevaUbicacion = relato.ubicacion;
      if (departamento != null && municipio != null) {
        try {
          nuevaUbicacion = Ubicacion(
            latitud: latitud ?? relato.ubicacion?.latitud ?? 0,
            longitud: longitud ?? relato.ubicacion?.longitud ?? 0,
            departamento: departamento,
            municipio: municipio,
          );
        } catch (e) {
          throw RelatoLocationException(e.toString());
        }
      }

      // Procesar multimedia
      List<Multimedia> nuevoMultimedia = relato.multimedia;
      
      if (imagenesUrls != null || audioUrl != null || videoUrl != null) {
        nuevoMultimedia = [];
        
        // Procesar imágenes
        if (imagenesUrls != null) {
          for (final url in imagenesUrls) {
            try {
              nuevoMultimedia.add(Multimedia(
                url: url,
                tipo: TipoMultimedia.imagen,
              ));
            } catch (e) {
              throw RelatoMediaException('Error con imagen $url: $e');
            }
          }
        }

        // Procesar audio
        if (audioUrl != null) {
          try {
            nuevoMultimedia.add(Multimedia(
              url: audioUrl,
              tipo: TipoMultimedia.audio,
            ));
          } catch (e) {
            throw RelatoMediaException('Error con audio $audioUrl: $e');
          }
        }

        // Procesar video
        if (videoUrl != null) {
          try {
            nuevoMultimedia.add(Multimedia(
              url: videoUrl,
              tipo: TipoMultimedia.video,
            ));
          } catch (e) {
            throw RelatoMediaException('Error con video $videoUrl: $e');
          }
        }
      }

      // Crear el relato actualizado
      final relatoActualizado = relato.copyWith(
        titulo: titulo,
        contenido: contenido,
        categoriaId: nuevaCategoriaId,
        categoriaNombre: nuevaCategoriaNombre,
        ubicacion: nuevaUbicacion,
        multimedia: nuevoMultimedia,
        etiquetas: etiquetas,
        fechaActualizacion: DateTime.now(),
      );

      // Validar el relato usando el validator
      try {
        _validator.validarRelato(relatoActualizado);
      } catch (e) {
        if (e is ContenidoValidationException) {
          throw RelatoInvalidContentException(e.message);
        }
        rethrow;
      }

      // Guardar el relato actualizado
      await _relatoRepository.guardarRelato(relatoActualizado);
      return Success<void, Failure>(null);
    } catch (e) {
      final failure = mapExceptionToFailure(e);
      return FailureResult<void, Failure>(failure);
    }
  }
}