import '../entities/evento_cultural.dart';
import '../entities/relato.dart';
import '../entities/saber_popular.dart';
import '../enums/tipos_contenido.dart';
import '../enums/estado_moderacion.dart';
import '../value_objects/multimedia.dart';
import '../value_objects/ubicacion.dart';

/// Validador para contenido de entidades principales
class ContenidoValidator {
  static const int MIN_TITULO_LENGTH = 5;
  static const int MAX_TITULO_LENGTH = 100;
  static const int MIN_DESCRIPCION_LENGTH = 20;
  static const int MAX_DESCRIPCION_LENGTH = 5000;
  static const int MAX_IMAGENES = 10;
  static const int MAX_VIDEOS = 3;
  static const int MAX_AUDIOS = 5;

  /// Valida un relato completo
  void validarRelato(Relato relato) {
    final errores = <String>[];

    if (relato.titulo.length < MIN_TITULO_LENGTH || relato.titulo.length > MAX_TITULO_LENGTH) {
      errores.add('El título debe tener entre $MIN_TITULO_LENGTH y $MAX_TITULO_LENGTH caracteres');
    }

    if (relato.contenido.length < MIN_DESCRIPCION_LENGTH || relato.contenido.length > MAX_DESCRIPCION_LENGTH) {
      errores.add('El contenido debe tener entre $MIN_DESCRIPCION_LENGTH y $MAX_DESCRIPCION_LENGTH caracteres');
    }

    try {
      validarMultimedia(relato.multimedia, TipoMultimedia.imagen);
    } catch (e) {
      if (e is ContenidoValidationException) {
        errores.addAll(e.errores);
      }
    }

    try {
      if (relato.ubicacion != null) {
        validarUbicacion(relato.ubicacion);
      }
    } catch (e) {
      if (e is ContenidoValidationException) {
        errores.addAll(e.errores);
      }
    }

    if (errores.isNotEmpty) {
      throw ContenidoValidationException('Relato inválido', errores);
    }
  }

  /// Valida un saber popular completo
  void validarSaberPopular(SaberPopular saber) {
    final errores = <String>[];

    if (saber.titulo.length < MIN_TITULO_LENGTH || saber.titulo.length > MAX_TITULO_LENGTH) {
      errores.add('El título debe tener entre $MIN_TITULO_LENGTH y $MAX_TITULO_LENGTH caracteres');
    }

    if (saber.contenido.length < MIN_DESCRIPCION_LENGTH || saber.contenido.length > MAX_DESCRIPCION_LENGTH) {
      errores.add('El contenido debe tener entre $MIN_DESCRIPCION_LENGTH y $MAX_DESCRIPCION_LENGTH caracteres');
    }

    try {
      validarMultimedia(saber.imagenes, TipoMultimedia.imagen);
    } catch (e) {
      if (e is ContenidoValidationException) {
        errores.addAll(e.errores);
      }
    }

    try {
      if (saber.ubicacion != null) {
        validarUbicacion(saber.ubicacion);
      }
    } catch (e) {
      if (e is ContenidoValidationException) {
        errores.addAll(e.errores);
      }
    }

    if (errores.isNotEmpty) {
      throw ContenidoValidationException('Saber popular inválido', errores);
    }
  }

  /// Valida un evento cultural completo
  void validarEventoCultural(EventoCultural evento) {
    final errores = <String>[];

    if (evento.titulo.length < MIN_TITULO_LENGTH || evento.titulo.length > MAX_TITULO_LENGTH) {
      errores.add('El nombre debe tener entre $MIN_TITULO_LENGTH y $MAX_TITULO_LENGTH caracteres');
    }

    if (evento.descripcion.length < MIN_DESCRIPCION_LENGTH || evento.descripcion.length > MAX_DESCRIPCION_LENGTH) {
      errores.add('La descripción debe tener entre $MIN_DESCRIPCION_LENGTH y $MAX_DESCRIPCION_LENGTH caracteres');
    }

    try {
      validarMultimedia(evento.imagenes, TipoMultimedia.imagen);
    } catch (e) {
      if (e is ContenidoValidationException) {
        errores.addAll(e.errores);
      }
    }

    try {
      validarUbicacion(evento.ubicacion);
    } catch (e) {
      if (e is ContenidoValidationException) {
        errores.addAll(e.errores);
      }
    }

    if (errores.isNotEmpty) {
      throw ContenidoValidationException('Evento cultural inválido', errores);
    }
  }

  /// Valida una sugerencia de evento
  void validarSugerenciaEvento(SugerenciaEvento sugerencia) {
    final errores = <String>[];

    if (sugerencia.nombre.length < MIN_TITULO_LENGTH || sugerencia.nombre.length > MAX_TITULO_LENGTH) {
      errores.add('El nombre debe tener entre $MIN_TITULO_LENGTH y $MAX_TITULO_LENGTH caracteres');
    }

    if (sugerencia.descripcion.length < MIN_DESCRIPCION_LENGTH || sugerencia.descripcion.length > MAX_DESCRIPCION_LENGTH) {
      errores.add('La descripción debe tener entre $MIN_DESCRIPCION_LENGTH y $MAX_DESCRIPCION_LENGTH caracteres');
    }

    try {
      validarMultimedia(sugerencia.imagenes, TipoMultimedia.imagen);
    } catch (e) {
      if (e is ContenidoValidationException) {
        errores.addAll(e.errores);
      }
    }

    try {
      validarUbicacion(sugerencia.ubicacion);
    } catch (e) {
      if (e is ContenidoValidationException) {
        errores.addAll(e.errores);
      }
    }

    if (errores.isNotEmpty) {
      throw ContenidoValidationException('Sugerencia de evento inválida', errores);
    }
  }

  /// Valida una lista de archivos multimedia
  void validarMultimedia(List<Multimedia> multimedia, TipoMultimedia tipoRequerido) {
    final errores = <String>[];

    if (multimedia.length > MAX_IMAGENES) {
      errores.add('No puede tener más de $MAX_IMAGENES archivos multimedia');
    }

    for (var item in multimedia) {
      if (item.tipo != tipoRequerido) {
        errores.add('El archivo ${item.url} debe ser de tipo ${tipoRequerido.value}');
      }
    }

    if (errores.isNotEmpty) {
      throw ContenidoValidationException('Multimedia inválida', errores);
    }
  }

  /// Valida una ubicación
  void validarUbicacion(Ubicacion? ubicacion) {
    final errores = <String>[];

    if (ubicacion == null) {
      throw ContenidoValidationException('Ubicación requerida', ['La ubicación es obligatoria']);
    }

    // La validación detallada ya se hace en el constructor de Ubicacion
    // Aquí solo validamos que exista

    if (errores.isNotEmpty) {
      throw ContenidoValidationException('Ubicación inválida', errores);
    }
  }

  /// Valida un estado de moderación
  void validarEstadoModeracion(EstadoModeracion estado) {
    // Validación simple para asegurar que es un estado válido
    if (!EstadoModeracion.values.contains(estado)) {
      throw ContenidoValidationException(
        'Estado de moderación inválido',
        ['El estado de moderación proporcionado no es válido']
      );
    }
  }
}

/// Excepción para errores de validación de contenido
class ContenidoValidationException implements Exception {
  final String message;
  final List<String> errores;

  ContenidoValidationException(this.message, this.errores);

  @override
  String toString() => '$message: ${errores.join(', ')}';
}