import '../../enums/tipos_juego.dart';

/// Clase base abstracta para todos los juegos
abstract class JuegoBase {
  final String id;
  final String titulo;
  final String descripcion;
  final TipoJuego tipo;
  final NivelDificultad dificultad;
  final int puntajeMaximo;
  final String? categoriaId;      // Categoría relacionada (opcional)
  final String? categoriaNombre;
  final bool activo;             // Si está disponible para jugar
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  const JuegoBase({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.dificultad,
    required this.puntajeMaximo,
    this.categoriaId,
    this.categoriaNombre,
    this.activo = true,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  /// Convierte a Map para Firestore
  Map<String, dynamic> toMap();

  /// Valida si una respuesta es correcta
  bool validarRespuesta(dynamic respuesta);

  /// Calcula el puntaje obtenido
  int calcularPuntaje(dynamic respuesta, Duration tiempoTranscurrido);
}