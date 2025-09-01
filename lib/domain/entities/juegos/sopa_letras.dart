import 'package:cloud_firestore/cloud_firestore.dart';
import 'juego_base.dart';
import '../../enums/tipos_juego.dart';

/// Palabra a encontrar en la sopa de letras
class PalabraSopa {
  final String palabra;
  final String pista;
  final String? significado;

  const PalabraSopa({
    required this.palabra,
    required this.pista,
    this.significado,
  });

  Map<String, dynamic> toMap() => {
    'palabra': palabra,
    'pista': pista,
    'significado': significado,
  };

  factory PalabraSopa.fromMap(Map<String, dynamic> map) => PalabraSopa(
    palabra: map['palabra'] as String,
    pista: map['pista'] as String,
    significado: map['significado'] as String?,
  );
}

/// Posición en la cuadrícula
class Posicion {
  final int fila;
  final int columna;

  const Posicion(this.fila, this.columna);

  Map<String, dynamic> toMap() => {
    'fila': fila,
    'columna': columna,
  };

  factory Posicion.fromMap(Map<String, dynamic> map) => Posicion(
    map['fila'] as int,
    map['columna'] as int,
  );
}

/// Dirección de la palabra
enum DireccionPalabra {
  horizontal,
  vertical,
  diagonal,
}

/// Palabra colocada en la cuadrícula
class PalabraColocada {
  final String palabra;
  final Posicion inicio;
  final DireccionPalabra direccion;

  const PalabraColocada({
    required this.palabra,
    required this.inicio,
    required this.direccion,
  });

  Map<String, dynamic> toMap() => {
    'palabra': palabra,
    'inicio': inicio.toMap(),
    'direccion': direccion.name,
  };

  factory PalabraColocada.fromMap(Map<String, dynamic> map) => PalabraColocada(
    palabra: map['palabra'] as String,
    inicio: Posicion.fromMap(map['inicio'] as Map<String, dynamic>),
    direccion: DireccionPalabra.values.firstWhere(
      (d) => d.name == map['direccion'],
    ),
  );
}

/// Juego de sopa de letras
class SopaLetras extends JuegoBase {
  final List<PalabraSopa> palabras;     // Palabras a encontrar
  final List<List<String>> cuadricula;  // Cuadrícula de letras
  final List<PalabraColocada> soluciones; // Posición de las palabras
  final int filas;                      // Tamaño de la cuadrícula
  final int columnas;
  final int tiempoLimite;              // Tiempo límite en segundos
  
  const SopaLetras({
    required super.id,
    required super.titulo,
    required super.descripcion,
    required this.palabras,
    required this.cuadricula,
    required this.soluciones,
    required this.filas,
    required this.columnas,
    this.tiempoLimite = 300,           // 5 minutos por defecto
    required super.dificultad,
    required super.puntajeMaximo,
    super.categoriaId,
    super.categoriaNombre,
    super.activo = true,
    required super.fechaCreacion,
    required super.fechaActualizacion,
  }) : super(tipo: TipoJuego.sopa_letras);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo.value,
      'palabras': palabras.map((p) => p.toMap()).toList(),
      'cuadricula': cuadricula,
      'soluciones': soluciones.map((s) => s.toMap()).toList(),
      'filas': filas,
      'columnas': columnas,
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
  factory SopaLetras.fromMap(Map<String, dynamic> map) {
    return SopaLetras(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      palabras: (map['palabras'] as List)
          .map((p) => PalabraSopa.fromMap(p as Map<String, dynamic>))
          .toList(),
      cuadricula: (map['cuadricula'] as List)
          .map((row) => List<String>.from(row as List))
          .toList(),
      soluciones: (map['soluciones'] as List)
          .map((s) => PalabraColocada.fromMap(s as Map<String, dynamic>))
          .toList(),
      filas: map['filas'] as int,
      columnas: map['columnas'] as int,
      tiempoLimite: map['tiempoLimite'] as int? ?? 300,
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
    if (respuesta is! List<PalabraColocada>) return false;
    if (respuesta.length != palabras.length) return false;

    // Verificar que cada palabra encontrada coincide con una solución
    for (final palabraEncontrada in respuesta) {
      bool encontrada = false;
      for (final solucion in soluciones) {
        if (palabraEncontrada.palabra == solucion.palabra &&
            palabraEncontrada.inicio.fila == solucion.inicio.fila &&
            palabraEncontrada.inicio.columna == solucion.inicio.columna &&
            palabraEncontrada.direccion == solucion.direccion) {
          encontrada = true;
          break;
        }
      }
      if (!encontrada) return false;
    }

    return true;
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

  /// Verifica si una palabra está en una posición específica
  bool verificarPalabra(String palabra, Posicion inicio, DireccionPalabra direccion) {
    final palabraColocada = PalabraColocada(
      palabra: palabra,
      inicio: inicio,
      direccion: direccion,
    );

    for (final solucion in soluciones) {
      if (solucion.palabra == palabraColocada.palabra &&
          solucion.inicio.fila == palabraColocada.inicio.fila &&
          solucion.inicio.columna == palabraColocada.inicio.columna &&
          solucion.direccion == palabraColocada.direccion) {
        return true;
      }
    }

    return false;
  }
}
