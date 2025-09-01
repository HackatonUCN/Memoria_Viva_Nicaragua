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
    required String userId,
    required this.contenidoId,
    required this.tipo,
    required this.titulo,
    this.departamento,
    this.municipio,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

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
    required String userId,
    required this.contenidoId,
    required this.tipo,
    required this.estadoAnterior,
    required this.estadoNuevo,
    this.razon,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

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
    required String userId,
    required this.contenidoId,
    required this.tipo,
    required this.razon,
    required this.reportadoPorId,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

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
    required String userId,
    required this.contenidoId,
    required this.tipo,
    required this.razon,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

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
    required String userId,
    required this.contenidoId,
    required this.tipo,
    required this.cambios,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

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
    required String userId,
    required this.contenidoId,
    required this.tipo,
    required this.titulo,
    this.eliminacionPermanente = false,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

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
    required String userId,
    required this.contenidoId,
    required this.tipo,
    required this.titulo,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

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
    required String userId,
    required this.contenidoId,
    required this.tipo,
    required this.comentarioId,
    required this.texto,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

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
    required String userId,
    required this.contenidoId,
    required this.tipo,
    required this.plataforma,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

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
    required String userId,
    required this.contenidoId,
    required this.tipo,
    required this.valoracion,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'contenidoId': contenidoId,
    'tipo': tipo.value,
    'valoracion': valoracion,
  };
}