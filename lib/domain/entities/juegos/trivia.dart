import 'package:cloud_firestore/cloud_firestore.dart';
import 'juego_base.dart';
import '../../enums/tipos_juego.dart';

/// Opción de respuesta para trivia
class OpcionTrivia {
  final String texto;
  final bool esCorrecta;
  final String? explicacion;

  const OpcionTrivia({
    required this.texto,
    required this.esCorrecta,
    this.explicacion,
  });

  Map<String, dynamic> toMap() => {
    'texto': texto,
    'esCorrecta': esCorrecta,
    'explicacion': explicacion,
  };

  factory OpcionTrivia.fromMap(Map<String, dynamic> map) => OpcionTrivia(
    texto: map['texto'] as String,
    esCorrecta: map['esCorrecta'] as bool,
    explicacion: map['explicacion'] as String?,
  );
}

/// Juego de trivia cultural
class Trivia extends JuegoBase {
  final String pregunta;
  final List<OpcionTrivia> opciones;
  final String? imagen;           // URL de imagen opcional
  final String? fuenteInfo;       // Fuente de la información
  final int tiempoLimite;        // Tiempo límite en segundos
  
  const Trivia({
    required super.id,
    required super.titulo,
    required super.descripcion,
    required this.pregunta,
    required this.opciones,
    this.imagen,
    this.fuenteInfo,
    this.tiempoLimite = 30,
    required super.dificultad,
    required super.puntajeMaximo,
    super.categoriaId,
    super.categoriaNombre,
    super.activo = true,
    required super.fechaCreacion,
    required super.fechaActualizacion,
  }) : super(tipo: TipoJuego.trivia);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo.value,
      'pregunta': pregunta,
      'opciones': opciones.map((o) => o.toMap()).toList(),
      'imagen': imagen,
      'fuenteInfo': fuenteInfo,
      'tiempoLimite': tiempoLimite,
      'dificultad': dificultad.value,
      'puntajeMaximo': puntajeMaximo,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
      'activo': activo,
      'fechaCreacion': fechaCreacion,
      'fechaActualizacion': fechaActualizacion,
    };
  }

  /// Crea desde Map de Firestore
  factory Trivia.fromMap(Map<String, dynamic> map) {
    return Trivia(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      pregunta: map['pregunta'] as String,
      opciones: (map['opciones'] as List)
          .map((o) => OpcionTrivia.fromMap(o as Map<String, dynamic>))
          .toList(),
      imagen: map['imagen'] as String?,
      fuenteInfo: map['fuenteInfo'] as String?,
      tiempoLimite: map['tiempoLimite'] as int? ?? 30,
      dificultad: NivelDificultad.values.firstWhere(
        (d) => d.value == map['dificultad'],
        orElse: () => NivelDificultad.facil,
      ),
      puntajeMaximo: map['puntajeMaximo'] as int,
      categoriaId: map['categoriaId'] as String?,
      categoriaNombre: map['categoriaNombre'] as String?,
      activo: map['activo'] as bool? ?? true,
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: (map['fechaActualizacion'] as Timestamp).toDate(),
    );
  }

  @override
  bool validarRespuesta(dynamic respuesta) {
    if (respuesta is! int) return false;
    if (respuesta < 0 || respuesta >= opciones.length) return false;
    return opciones[respuesta].esCorrecta;
  }

  @override
  int calcularPuntaje(dynamic respuesta, Duration tiempoTranscurrido) {
    if (!validarRespuesta(respuesta)) return 0;
    if (tiempoTranscurrido.inSeconds > tiempoLimite) return 0;

    // Base: puntaje máximo
    int puntaje = puntajeMaximo;

    // Reducir por tiempo (máximo 50% de reducción)
    final segundos = tiempoTranscurrido.inSeconds;
    final reduccionTiempo = (segundos / tiempoLimite) * (puntaje * 0.5);
    
    puntaje -= reduccionTiempo.toInt();

    return puntaje.clamp(0, puntajeMaximo);
  }

  /// Obtiene la explicación de una opción
  String? getExplicacion(int indiceOpcion) {
    if (indiceOpcion < 0 || indiceOpcion >= opciones.length) return null;
    return opciones[indiceOpcion].explicacion;
  }
}
