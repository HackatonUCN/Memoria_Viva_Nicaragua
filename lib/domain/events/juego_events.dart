import '../entities/juegos/juego_base.dart';
import '../enums/tipos_juego.dart';
import 'domain_event.dart';

class JuegoIniciado extends DomainEvent {
  final String juegoId;
  final TipoJuego tipo;
  final NivelDificultad dificultad;
  final String? categoriaId;

  JuegoIniciado({
    required String userId,
    required this.juegoId,
    required this.tipo,
    required this.dificultad,
    this.categoriaId,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'juegoId': juegoId,
    'tipo': tipo.value,
    'dificultad': dificultad.value,
    'categoriaId': categoriaId,
  };
}

class JuegoCompletado extends DomainEvent {
  final String juegoId;
  final TipoJuego tipo;
  final NivelDificultad dificultad;
  final int puntaje;
  final int duracionSegundos;
  final bool completado;
  final int estrellas; // 0-3 estrellas

  JuegoCompletado({
    required String userId,
    required this.juegoId,
    required this.tipo,
    required this.dificultad,
    required this.puntaje,
    required this.duracionSegundos,
    required this.completado,
    required this.estrellas,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'juegoId': juegoId,
    'tipo': tipo.value,
    'dificultad': dificultad.value,
    'puntaje': puntaje,
    'duracionSegundos': duracionSegundos,
    'completado': completado,
    'estrellas': estrellas,
  };
}

class JuegoAbandonado extends DomainEvent {
  final String juegoId;
  final TipoJuego tipo;
  final NivelDificultad dificultad;
  final int duracionSegundos;
  final int progresoPocentaje;

  JuegoAbandonado({
    required String userId,
    required this.juegoId,
    required this.tipo,
    required this.dificultad,
    required this.duracionSegundos,
    required this.progresoPocentaje,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'juegoId': juegoId,
    'tipo': tipo.value,
    'dificultad': dificultad.value,
    'duracionSegundos': duracionSegundos,
    'progresoPocentaje': progresoPocentaje,
  };
}

class JuegoReiniciadoEvent extends DomainEvent {
  final String juegoId;
  final TipoJuego tipo;
  final String razon;

  JuegoReiniciadoEvent({
    required String userId,
    required this.juegoId,
    required this.tipo,
    required this.razon,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'juegoId': juegoId,
    'tipo': tipo.value,
    'razon': razon,
  };
}

class JuegoNuevoRecordEvent extends DomainEvent {
  final String juegoId;
  final TipoJuego tipo;
  final NivelDificultad dificultad;
  final int puntajeAnterior;
  final int nuevoRecord;

  JuegoNuevoRecordEvent({
    required String userId,
    required this.juegoId,
    required this.tipo,
    required this.dificultad,
    required this.puntajeAnterior,
    required this.nuevoRecord,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'juegoId': juegoId,
    'tipo': tipo.value,
    'dificultad': dificultad.value,
    'puntajeAnterior': puntajeAnterior,
    'nuevoRecord': nuevoRecord,
  };
}

class JuegoDesafioCompletadoEvent extends DomainEvent {
  final String desafioId;
  final String titulo;
  final int puntos;
  final String? recompensa;

  JuegoDesafioCompletadoEvent({
    required String userId,
    required this.desafioId,
    required this.titulo,
    required this.puntos,
    this.recompensa,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'desafioId': desafioId,
    'titulo': titulo,
    'puntos': puntos,
    'recompensa': recompensa,
  };
}
