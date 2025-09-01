import 'package:cloud_firestore/cloud_firestore.dart';

import '../../entities/saber_popular.dart';
import '../../entities/user.dart';
import '../../enums/roles_usuario.dart';
import '../../exceptions/auth_exception.dart';
import '../../exceptions/saber_exception.dart';
import '../../exceptions/categoria_exception.dart';
import '../../repositories/saber_popular_repository.dart';
import '../../repositories/categoria_repository.dart';
import '../../repositories/user_repository.dart';
import '../../validators/contenido_validator.dart';
import '../../value_objects/ubicacion.dart';
import '../../value_objects/multimedia.dart';
import '../../aggregates/saber_popular_aggregate.dart';
import '../../events/saber_popular_events.dart';

/// Caso de uso para actualizar un saber popular existente
class ActualizarSaberUseCase {
  final ISaberPopularRepository _saberRepository;
  final ICategoriaRepository _categoriaRepository;
  final IUserRepository _userRepository;
  final ContenidoValidator _validator;

  ActualizarSaberUseCase(
    this._saberRepository,
    this._categoriaRepository,
    this._userRepository,
    this._validator,
  );

  /// Actualiza un saber popular existente utilizando el agregado SaberPopularAggregate
  /// 
  /// [usuarioId] - ID del usuario que intenta actualizar
  /// 
  /// Throws:
  /// - [SaberNotFoundException] si el saber no existe
  /// - [SaberPermissionException] si no tiene permisos
  /// - [SaberInvalidContentException] si el contenido es inválido
  /// - [CategoriaNotFoundException] si la categoría no existe
  /// - [SaberException] para otros errores
  Future<void> execute({
    required String saberId,
    required String usuarioId,
    String? titulo,
    String? contenido,
    String? categoriaId,
    String? departamento,
    String? municipio,
    double? latitud,
    double? longitud,
    List<String>? imagenesUrls,
    List<String>? etiquetas,
  }) async {
    try {
      // Obtener el saber
      final saber = await _saberRepository.obtenerSaberPorId(saberId);
      if (saber == null) {
        throw SaberNotFoundException();
      }

      // Verificar permisos
      final usuario = await _userRepository.obtenerUsuarioPorId(usuarioId);
      if (usuario == null) {
        throw UserNotFoundException();
      }

      // Solo el autor o un admin pueden editar
      if (saber.autorId != usuarioId && usuario.rol != UserRole.admin) {
        throw SaberPermissionException(
          'No tienes permisos para editar este saber popular'
        );
      }

      // Si se cambia la categoría, validarla
      String nuevaCategoriaId = categoriaId ?? saber.categoriaId;
      String nuevaCategoriaNombre = saber.categoriaNombre;
      
      if (categoriaId != null && categoriaId != saber.categoriaId) {
        final categoria = await _categoriaRepository.obtenerCategoriaPorId(categoriaId);
        if (categoria == null) {
          throw CategoriaNotFoundException.withId(categoriaId);
        }
        nuevaCategoriaNombre = categoria.nombre;
      }

      // Crear ubicación si se proporcionaron nuevas coordenadas
      Ubicacion? nuevaUbicacion = saber.ubicacion;
      if (departamento != null && municipio != null) {
        try {
          nuevaUbicacion = Ubicacion(
            latitud: latitud ?? saber.ubicacion?.latitud ?? 0,
            longitud: longitud ?? saber.ubicacion?.longitud ?? 0,
            departamento: departamento,
            municipio: municipio,
          );
        } catch (e) {
          throw SaberLocationException.fromError(e.toString());
        }
      }

      // Procesar imágenes
      List<Multimedia> nuevasImagenes = saber.imagenes;
      if (imagenesUrls != null) {
        nuevasImagenes = [];
        for (final url in imagenesUrls) {
          try {
            nuevasImagenes.add(Multimedia(
              url: url,
              tipo: TipoMultimedia.imagen,
            ));
          } catch (e) {
            throw SaberMediaException.formatoInvalido(url);
          }
        }
      }

      // Obtener comentarios y verificaciones (en una implementación real se obtendrían del repositorio)
      final comentarios = <ComentarioSaber>[];
      final verificaciones = <VerificacionSaber>[];
      
      // Crear el agregado
      final saberAggregate = SaberPopularAggregate(saber, comentarios, verificaciones);
      
      // Actualizar el saber a través del agregado
      final saberActualizadoAggregate = saberAggregate.actualizarSaber(
        titulo: titulo,
        contenido: contenido,
        categoriaId: nuevaCategoriaId,
        categoriaNombre: nuevaCategoriaNombre,
        ubicacion: nuevaUbicacion,
        imagenes: nuevasImagenes,
        etiquetas: etiquetas,
      );
      
      // Obtener el saber actualizado
      final saberActualizado = saberActualizadoAggregate.saber;
      
      // Validar usando el validator
      try {
        _validator.validarSaberPopular(saberActualizado);
      } catch (e) {
        if (e is ContenidoValidationException) {
          throw SaberInvalidContentException.fromValidation(e.message);
        }
        rethrow;
      }
      
      // Obtener eventos generados
      final eventos = saberActualizadoAggregate.obtenerYLimpiarEventos();
      
      // Guardar el saber actualizado
      await _saberRepository.actualizarSaber(saberActualizado);
      
      // TODO: Publicar eventos de dominio
      // for (final evento in eventos) {
      //   eventBus.publish(evento);
      // }

    } catch (e) {
      if (e is SaberNotFoundException || 
          e is UserNotFoundException ||
          e is SaberPermissionException ||
          e is CategoriaNotFoundException ||
          e is SaberInvalidContentException ||
          e is SaberLocationException ||
          e is SaberMediaException) {
        rethrow;
      }
      throw SaberException('Error al actualizar saber popular: $e');
    }
  }
}