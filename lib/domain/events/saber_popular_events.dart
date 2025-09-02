import '../enums/tipos_contenido.dart';
import '../enums/estado_moderacion.dart';
import '../value_objects/ubicacion.dart';
import 'domain_event.dart';

/// Evento cuando se crea un nuevo saber popular
class SaberPopularCreado extends DomainEvent {
  final String saberId;
  final String titulo;
  final String categoriaId;
  final String categoriaNombre;
  final Ubicacion? ubicacion;
  final List<String> etiquetas;

  SaberPopularCreado({
    required super.userId,
    required this.saberId,
    required this.titulo,
    required this.categoriaId,
    required this.categoriaNombre,
    this.ubicacion,
    this.etiquetas = const [],
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'saberId': saberId,
    'titulo': titulo,
    'categoriaId': categoriaId,
    'categoriaNombre': categoriaNombre,
    'ubicacion': ubicacion?.toMap(),
    'etiquetas': etiquetas,
    'tipoContenido': TipoContenido.saber.value,
  };
}

/// Evento cuando se actualiza un saber popular
class SaberPopularActualizado extends DomainEvent {
  final String saberId;
  final String titulo;
  final Map<String, dynamic> cambios;

  SaberPopularActualizado({
    required super.userId,
    required this.saberId,
    required this.titulo,
    required this.cambios,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'saberId': saberId,
    'titulo': titulo,
    'cambios': cambios,
    'tipoContenido': TipoContenido.saber.value,
  };
}

/// Evento cuando se modera un saber popular
class SaberPopularModerado extends DomainEvent {
  final String saberId;
  final String titulo;
  final EstadoModeracion estadoAnterior;
  final EstadoModeracion estadoNuevo;
  final String? razon;
  final bool procesado;

  SaberPopularModerado({
    required super.userId,
    required this.saberId,
    required this.titulo,
    required this.estadoAnterior,
    required this.estadoNuevo,
    this.razon,
    this.procesado = true,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'saberId': saberId,
    'titulo': titulo,
    'estadoAnterior': estadoAnterior.value,
    'estadoNuevo': estadoNuevo.value,
    'razon': razon,
    'procesado': procesado,
    'tipoContenido': TipoContenido.saber.value,
  };
}

/// Evento cuando se reporta un saber popular
class SaberPopularReportado extends DomainEvent {
  final String saberId;
  final String titulo;
  final String razon;
  final String reportadoPorId;
  final int reportesActuales;

  SaberPopularReportado({
    required super.userId,
    required this.saberId,
    required this.titulo,
    required this.razon,
    required this.reportadoPorId,
    required this.reportesActuales,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'saberId': saberId,
    'titulo': titulo,
    'razon': razon,
    'reportadoPorId': reportadoPorId,
    'reportesActuales': reportesActuales,
    'tipoContenido': TipoContenido.saber.value,
  };
}

/// Evento cuando se elimina un saber popular
class SaberPopularEliminado extends DomainEvent {
  final String saberId;
  final String titulo;
  final bool eliminacionPermanente;

  SaberPopularEliminado({
    required super.userId,
    required this.saberId,
    required this.titulo,
    this.eliminacionPermanente = false,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'saberId': saberId,
    'titulo': titulo,
    'eliminacionPermanente': eliminacionPermanente,
    'tipoContenido': TipoContenido.saber.value,
  };
}

/// Evento cuando se restaura un saber popular eliminado
class SaberPopularRestaurado extends DomainEvent {
  final String saberId;
  final String titulo;

  SaberPopularRestaurado({
    required super.userId,
    required this.saberId,
    required this.titulo,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'saberId': saberId,
    'titulo': titulo,
    'tipoContenido': TipoContenido.saber.value,
  };
}

/// Evento cuando se destaca un saber popular
class SaberPopularDestacado extends DomainEvent {
  final String saberId;
  final String titulo;
  final String razon;

  SaberPopularDestacado({
    required super.userId,
    required this.saberId,
    required this.titulo,
    required this.razon,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'saberId': saberId,
    'titulo': titulo,
    'razon': razon,
    'tipoContenido': TipoContenido.saber.value,
  };
}

/// Evento cuando se valora un saber popular
class SaberPopularValorado extends DomainEvent {
  final String saberId;
  final String titulo;
  final int valoracion; // 1-5 estrellas

  SaberPopularValorado({
    required super.userId,
    required this.saberId,
    required this.titulo,
    required this.valoracion,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'saberId': saberId,
    'titulo': titulo,
    'valoracion': valoracion,
    'tipoContenido': TipoContenido.saber.value,
  };
}

/// Evento cuando se comparte un saber popular
class SaberPopularCompartido extends DomainEvent {
  final String saberId;
  final String titulo;
  final String plataforma;

  SaberPopularCompartido({
    required super.userId,
    required this.saberId,
    required this.titulo,
    required this.plataforma,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'saberId': saberId,
    'titulo': titulo,
    'plataforma': plataforma,
    'tipoContenido': TipoContenido.saber.value,
  };
}

/// Evento cuando se verifica la autenticidad de un saber popular
class SaberPopularVerificado extends DomainEvent {
  final String saberId;
  final String titulo;
  final bool esAutentico;
  final String? comentario;

  SaberPopularVerificado({
    required super.userId,
    required this.saberId,
    required this.titulo,
    required this.esAutentico,
    this.comentario,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'saberId': saberId,
    'titulo': titulo,
    'esAutentico': esAutentico,
    'comentario': comentario,
    'tipoContenido': TipoContenido.saber.value,
  };
}
