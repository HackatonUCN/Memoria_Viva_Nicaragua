import '../enums/tipos_contenido.dart';
import '../enums/estado_moderacion.dart';
import 'domain_event.dart';

class ContenidoCreado extends DomainEvent {
  final String contenidoId;
  final TipoContenido tipo;
  final String titulo;
  final String? departamento;
  final String? municipio;

  ContenidoCreado({
    required super.userId,
    required this.contenidoId,
    required this.tipo,
    required this.titulo,
    this.departamento,
    this.municipio,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'contenidoId': contenidoId,
    'tipo': tipo.value,
    'titulo': titulo,
    'departamento': departamento,
    'municipio': municipio,
  };
}

class ContenidoModerado extends DomainEvent {
  final String contenidoId;
  final TipoContenido tipo;
  final EstadoModeracion estadoAnterior;
  final EstadoModeracion estadoNuevo;
  final String? razon;

  ContenidoModerado({
    required super.userId,
    required this.contenidoId,
    required this.tipo,
    required this.estadoAnterior,
    required this.estadoNuevo,
    this.razon,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'contenidoId': contenidoId,
    'tipo': tipo.value,
    'estadoAnterior': estadoAnterior.value,
    'estadoNuevo': estadoNuevo.value,
    'razon': razon,
  };
}

class ContenidoReportado extends DomainEvent {
  final String contenidoId;
  final TipoContenido tipo;
  final String razon;
  final String reportadoPorId;

  ContenidoReportado({
    required super.userId,
    required this.contenidoId,
    required this.tipo,
    required this.razon,
    required this.reportadoPorId,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'contenidoId': contenidoId,
    'tipo': tipo.value,
    'razon': razon,
    'reportadoPorId': reportadoPorId,
  };
}

class ContenidoDestacado extends DomainEvent {
  final String contenidoId;
  final TipoContenido tipo;
  final String razon;

  ContenidoDestacado({
    required super.userId,
    required this.contenidoId,
    required this.tipo,
    required this.razon,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'contenidoId': contenidoId,
    'tipo': tipo.value,
    'razon': razon,
  };
}

class ContenidoActualizado extends DomainEvent {
  final String contenidoId;
  final TipoContenido tipo;
  final Map<String, dynamic> cambios;

  ContenidoActualizado({
    required super.userId,
    required this.contenidoId,
    required this.tipo,
    required this.cambios,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'contenidoId': contenidoId,
    'tipo': tipo.value,
    'cambios': cambios,
  };
}

class ContenidoEliminado extends DomainEvent {
  final String contenidoId;
  final TipoContenido tipo;
  final String titulo;
  final bool eliminacionPermanente;

  ContenidoEliminado({
    required super.userId,
    required this.contenidoId,
    required this.tipo,
    required this.titulo,
    this.eliminacionPermanente = false,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'contenidoId': contenidoId,
    'tipo': tipo.value,
    'titulo': titulo,
    'eliminacionPermanente': eliminacionPermanente,
  };
}

class ContenidoRestaurado extends DomainEvent {
  final String contenidoId;
  final TipoContenido tipo;
  final String titulo;

  ContenidoRestaurado({
    required super.userId,
    required this.contenidoId,
    required this.tipo,
    required this.titulo,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'contenidoId': contenidoId,
    'tipo': tipo.value,
    'titulo': titulo,
  };
}

class ContenidoComentado extends DomainEvent {
  final String contenidoId;
  final TipoContenido tipo;
  final String comentarioId;
  final String texto;

  ContenidoComentado({
    required super.userId,
    required this.contenidoId,
    required this.tipo,
    required this.comentarioId,
    required this.texto,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'contenidoId': contenidoId,
    'tipo': tipo.value,
    'comentarioId': comentarioId,
    'texto': texto,
  };
}

class ContenidoCompartido extends DomainEvent {
  final String contenidoId;
  final TipoContenido tipo;
  final String plataforma;

  ContenidoCompartido({
    required super.userId,
    required this.contenidoId,
    required this.tipo,
    required this.plataforma,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'contenidoId': contenidoId,
    'tipo': tipo.value,
    'plataforma': plataforma,
  };
}

class ContenidoValorado extends DomainEvent {
  final String contenidoId;
  final TipoContenido tipo;
  final int valoracion; // 1-5 estrellas

  ContenidoValorado({
    required super.userId,
    required this.contenidoId,
    required this.tipo,
    required this.valoracion,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'contenidoId': contenidoId,
    'tipo': tipo.value,
    'valoracion': valoracion,
  };
}