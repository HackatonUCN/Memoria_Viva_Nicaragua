import '../enums/tipos_evento.dart';
import 'domain_event.dart';

class EventoCreado extends DomainEvent {
  final String eventoId;
  final String nombre;
  final TipoEvento tipo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? departamento;
  final String? municipio;

  EventoCreado({
    required super.userId,
    required this.eventoId,
    required this.nombre,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    this.departamento,
    this.municipio,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'eventoId': eventoId,
    'nombre': nombre,
    'tipo': tipo.value,
    'fechaInicio': fechaInicio.toIso8601String(),
    'fechaFin': fechaFin.toIso8601String(),
    'departamento': departamento,
    'municipio': municipio,
  };
}

class EventoActualizado extends DomainEvent {
  final String eventoId;
  final String nombre;
  final Map<String, dynamic> cambios;

  EventoActualizado({
    required super.userId,
    required this.eventoId,
    required this.nombre,
    required this.cambios,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'eventoId': eventoId,
    'nombre': nombre,
    'cambios': cambios,
  };
}

class EventoEliminado extends DomainEvent {
  final String eventoId;
  final String nombre;
  final TipoEvento tipo;

  EventoEliminado({
    required super.userId,
    required this.eventoId,
    required this.nombre,
    required this.tipo,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'eventoId': eventoId,
    'nombre': nombre,
    'tipo': tipo.value,
  };
}

class EventoRestaurado extends DomainEvent {
  final String eventoId;
  final String nombre;

  EventoRestaurado({
    required super.userId,
    required this.eventoId,
    required this.nombre,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'eventoId': eventoId,
    'nombre': nombre,
  };
}

class SugerenciaEventoCreada extends DomainEvent {
  final String sugerenciaId;
  final String nombre;
  final TipoEvento tipo;
  final DateTime fechaInicio;
  final DateTime fechaFin;

  SugerenciaEventoCreada({
    required super.userId,
    required this.sugerenciaId,
    required this.nombre,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'sugerenciaId': sugerenciaId,
    'nombre': nombre,
    'tipo': tipo.value,
    'fechaInicio': fechaInicio.toIso8601String(),
    'fechaFin': fechaFin.toIso8601String(),
  };
}

class SugerenciaEventoAprobada extends DomainEvent {
  final String sugerenciaId;
  final String eventoId;
  final String nombre;

  SugerenciaEventoAprobada({
    required super.userId,
    required this.sugerenciaId,
    required this.eventoId,
    required this.nombre,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'sugerenciaId': sugerenciaId,
    'eventoId': eventoId,
    'nombre': nombre,
  };
}

class SugerenciaEventoRechazada extends DomainEvent {
  final String sugerenciaId;
  final String nombre;
  final String razon;

  SugerenciaEventoRechazada({
    required super.userId,
    required this.sugerenciaId,
    required this.nombre,
    required this.razon,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'sugerenciaId': sugerenciaId,
    'nombre': nombre,
    'razon': razon,
  };
}

class EventoProximo extends DomainEvent {
  final String eventoId;
  final String nombre;
  final TipoEvento tipo;
  final DateTime fechaInicio;
  final int diasFaltantes;

  EventoProximo({
    required super.userId,
    required this.eventoId,
    required this.nombre,
    required this.tipo,
    required this.fechaInicio,
    required this.diasFaltantes,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'eventoId': eventoId,
    'nombre': nombre,
    'tipo': tipo.value,
    'fechaInicio': fechaInicio.toIso8601String(),
    'diasFaltantes': diasFaltantes,
  };
}

class EventoParticipacionRegistrada extends DomainEvent {
  final String eventoId;
  final String nombre;
  final String tipoParticipacion; // asistencia, organizador, etc.

  EventoParticipacionRegistrada({
    required super.userId,
    required this.eventoId,
    required this.nombre,
    required this.tipoParticipacion,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'eventoId': eventoId,
    'nombre': nombre,
    'tipoParticipacion': tipoParticipacion,
  };
}
