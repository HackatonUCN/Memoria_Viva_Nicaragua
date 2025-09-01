import 'package:cloud_firestore/cloud_firestore.dart';

import '../../entities/evento_cultural.dart';
import '../../entities/user.dart';
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

/// Caso de uso para crear un nuevo evento cultural (solo admin)
class CrearEventoUseCase {
  final IEventoCulturalRepository _eventoRepository;
  final ICategoriaRepository _categoriaRepository;
  final IUserRepository _userRepository;
  final ContenidoValidator _validator;

  CrearEventoUseCase(
    this._eventoRepository,
    this._categoriaRepository,
    this._userRepository,
    this._validator,
  );

  /// Crea un nuevo evento cultural
  /// 
  /// [adminId] - ID del administrador que crea el evento
  /// 
  /// Throws:
  /// - [EventoPermissionException] si no es admin
  /// - [EventoInvalidContentException] si el contenido es inválido
  /// - [EventoInvalidDateException] si las fechas son inválidas
  /// - [EventoDuplicadoException] si ya existe un evento similar
  /// - [CategoriaNotFoundException] si la categoría no existe
  /// - [EventoException] para otros errores
  Future<EventoCultural> execute({
    required String adminId,
    required String nombre,
    required String descripcion,
    required TipoEvento tipo,
    required String categoriaId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String organizador,
    String? departamento = '',
    String? municipio = '',
    double? latitud,
    double? longitud,
    List<String> imagenesUrls = const [],
    bool esRecurrente = false,
    String? frecuencia,
    String? contacto,
  }) async {
    try {
      // Verificar que el usuario sea admin
      final admin = await _userRepository.obtenerUsuarioPorId(adminId);
      if (admin == null) {
        throw UserNotFoundException.withId(adminId);
      }
      if (admin.rol != UserRole.admin) {
        throw EventoPermissionException('Solo los administradores pueden crear eventos');
      }

      // Verificar que la categoría exista
      final categoria = await _categoriaRepository.obtenerCategoriaPorId(categoriaId);
      if (categoria == null) {
        throw CategoriaNotFoundException.withId(categoriaId);
      }

      // Validar fechas
      if (fechaInicio.isAfter(fechaFin)) {
        throw EventoInvalidDateException.fechaInicioMayorQueFin();
      }
      if (fechaInicio.isBefore(DateTime.now()) && !esRecurrente) {
        throw EventoInvalidDateException.fechaPasada();
      }

      // Verificar si ya existe un evento similar
      final eventosExistentes = await _eventoRepository.buscarEventos(nombre);
      final eventosSimilares = eventosExistentes.where((e) => 
        e.fechaInicio.isAtSameMomentAs(fechaInicio) || 
        e.fechaFin.isAtSameMomentAs(fechaFin) ||
        (e.fechaInicio.isBefore(fechaFin) && e.fechaFin.isAfter(fechaInicio))
      ).toList();
      
      if (eventosSimilares.isNotEmpty) {
        throw EventoDuplicadoException();
      }

      // Crear la ubicación si se proporcionaron datos
      Ubicacion ubicacion;
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
          throw EventoLocationException.fromError(e.toString());
        }
      } else {
        throw EventoLocationException.ubicacionRequerida();
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
          throw EventoMediaException.fromError('Error con imagen $url: $e');
        }
      }

      // Crear el evento
      final evento = EventoCultural.crear(
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
        creadoPorId: adminId,
      );

      // Validar usando el validator
      try {
        _validator.validarEventoCultural(evento);
      } catch (e) {
        if (e is ContenidoValidationException) {
          throw EventoInvalidContentException.fromValidation(e.message);
        }
        rethrow;
      }

      // Guardar el evento
      await _eventoRepository.guardarEvento(evento);

      return evento;
    } catch (e) {
      if (e is EventoPermissionException ||
          e is CategoriaNotFoundException ||
          e is EventoInvalidContentException ||
          e is EventoInvalidDateException ||
          e is EventoDuplicadoException ||
          e is EventoLocationException ||
          e is EventoMediaException) {
        rethrow;
      }
      throw EventoException('Error al crear evento: $e');
    }
  }
}