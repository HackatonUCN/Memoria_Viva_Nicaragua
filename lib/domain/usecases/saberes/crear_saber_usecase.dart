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

/// Caso de uso para crear un nuevo saber popular
class CrearSaberUseCase {
  final ISaberPopularRepository _saberRepository;
  final ICategoriaRepository _categoriaRepository;
  final IUserRepository _userRepository;
  final ContenidoValidator _validator;

  CrearSaberUseCase(
    this._saberRepository,
    this._categoriaRepository,
    this._userRepository,
    this._validator,
  );

  /// Crea un nuevo saber popular utilizando el agregado SaberPopularAggregate
  /// 
  /// Throws:
  /// - [SaberInvalidContentException] si el contenido es inválido
  /// - [SaberMediaException] si hay error con las imágenes
  /// - [SaberLocationException] si hay error con la ubicación
  /// - [CategoriaNotFoundException] si la categoría no existe
  /// - [UserNotFoundException] si el usuario no existe
  /// - [SaberException] para otros errores
  Future<SaberPopular> execute({
    required String titulo,
    required String contenido,
    required String autorId,
    required String categoriaId,
    String? departamento,
    String? municipio,
    double? latitud,
    double? longitud,
    List<String> imagenesUrls = const [],
    List<String> etiquetas = const [],
  }) async {
    try {
      // Validar usuario
      final autor = await _userRepository.obtenerUsuarioPorId(autorId);
      if (autor == null) {
        throw UserNotFoundException.withId(autorId);
      }

      // Validar que no sea usuario invitado
      if (autor.rol == UserRole.invitado) {
        throw SaberPermissionException(
          'Los usuarios invitados no pueden crear saberes populares'
        );
      }

      // Validar categoría
      final categoria = await _categoriaRepository.obtenerCategoriaPorId(categoriaId);
      if (categoria == null) {
        throw CategoriaNotFoundException.withId(categoriaId);
      }

      // Crear ubicación si se proporcionaron datos
      Ubicacion? ubicacion;
      if (departamento != null && departamento.isNotEmpty && 
          municipio != null && municipio.isNotEmpty) {
        try {
          ubicacion = Ubicacion(
            latitud: latitud ?? 0,
            longitud: longitud ?? 0,
            departamento: departamento,
            municipio: municipio,
          );
        } catch (e) {
          throw SaberLocationException.fromError(e.toString());
        }
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
          throw SaberMediaException.fromError('Error con imagen $url: $e');
        }
      }

      // Verificar si ya existe un saber similar
      final saberesSimilares = await _saberRepository.buscarSaberesSimilares(
        titulo: titulo,
        categoriaId: categoriaId,
      );
      if (saberesSimilares.isNotEmpty) {
        throw SaberDuplicadoException();
      }

      // Crear el saber popular
      final saber = SaberPopular.crear(
        titulo: titulo,
        contenido: contenido,
        autorId: autorId,
        autorNombre: autor.nombre,
        categoriaId: categoriaId,
        categoriaNombre: categoria.nombre,
        ubicacion: ubicacion,
        imagenes: imagenes,
        etiquetas: etiquetas,
      );

      // Validar usando el validator
      try {
        _validator.validarSaberPopular(saber);
      } catch (e) {
        if (e is ContenidoValidationException) {
          throw SaberInvalidContentException.fromValidation(e.message);
        }
        rethrow;
      }

      // Crear el agregado con el saber y listas vacías de comentarios y verificaciones
      final saberAggregate = SaberPopularAggregate(saber, [], []);
      
      // Crear evento de dominio
      final evento = SaberPopularCreado(
        userId: autorId,
        saberId: saber.id,
        titulo: saber.titulo,
        categoriaId: saber.categoriaId,
        categoriaNombre: saber.categoriaNombre,
        ubicacion: saber.ubicacion,
        etiquetas: saber.etiquetas,
      );
      
      // Guardar el saber
      await _saberRepository.guardarSaber(saber);
      
      // TODO: Publicar evento de dominio
      // eventBus.publish(evento);
      
      return saber;
    } catch (e) {
      if (e is SaberPermissionException ||
          e is CategoriaNotFoundException ||
          e is SaberInvalidContentException ||
          e is SaberLocationException ||
          e is SaberMediaException ||
          e is SaberDuplicadoException) {
        rethrow;
      }
      throw SaberException('Error al crear saber popular: $e');
    }
  }
}