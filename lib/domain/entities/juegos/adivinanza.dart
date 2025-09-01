import 'package:cloud_firestore/cloud_firestore.dart';
import '../../enums/tipos_juego.dart';
import 'juego_base.dart';

/// Juego de adivinanzas
class Adivinanza extends JuegoBase {
  final String pregunta;           // La adivinanza
  final String respuestaCorrecta;  // Respuesta esperada
  final List<String> pistas;       // Pistas opcionales
  final int intentosMaximos;       // Intentos permitidos
  
  const Adivinanza({
    required super.id,
    required super.titulo,
    required super.descripcion,
    required this.pregunta,
    required this.respuestaCorrecta,
    required super.dificultad,
    required super.puntajeMaximo,
    this.pistas = const [],
    this.intentosMaximos = 3,
    super.categoriaId,
    super.categoriaNombre,
    super.activo = true,
    required super.fechaCreacion,
    required super.fechaActualizacion,
  }) : super(tipo: TipoJuego.adivinanza);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo.value,
      'pregunta': pregunta,
      'respuestaCorrecta': respuestaCorrecta,
      'pistas': pistas,
      'intentosMaximos': intentosMaximos,
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
  factory Adivinanza.fromMap(Map<String, dynamic> map) {
    return Adivinanza(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      pregunta: map['pregunta'] as String,
      respuestaCorrecta: map['respuestaCorrecta'] as String,
      pistas: List<String>.from(map['pistas'] ?? []),
      intentosMaximos: map['intentosMaximos'] as int? ?? 3,
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
    if (respuesta is! String) return false;
    return respuesta.trim().toLowerCase() == respuestaCorrecta.toLowerCase();
  }

  @override
  int calcularPuntaje(dynamic respuesta, Duration tiempoTranscurrido) {
    if (!validarRespuesta(respuesta)) return 0;

    // Base: puntaje máximo
    int puntaje = puntajeMaximo;

    // Reducir por tiempo (máximo 50% de reducción)
    final segundos = tiempoTranscurrido.inSeconds;
    final reduccionTiempo = (segundos > 60) 
        ? puntaje * 0.5 
        : (segundos / 60) * (puntaje * 0.5);
    
    puntaje -= reduccionTiempo.toInt();

    // Reducir por pistas usadas (20% por pista)
    final pistasUsadas = pistas.length;
    final reduccionPistas = (puntaje * 0.2) * pistasUsadas;
    
    puntaje -= reduccionPistas.toInt();

    return puntaje.clamp(0, puntajeMaximo);
  }
}
