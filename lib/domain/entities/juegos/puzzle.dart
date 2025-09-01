import 'package:cloud_firestore/cloud_firestore.dart';
import '../../enums/tipos_juego.dart';
import 'juego_base.dart';

/// Pieza del puzzle
class PiezaPuzzle {
  final int indiceOriginal;  // Posición original en la imagen
  final int indiceActual;    // Posición actual
  final String imagenUrl;    // URL de la pieza recortada

  const PiezaPuzzle({
    required this.indiceOriginal,
    required this.indiceActual,
    required this.imagenUrl,
  });

  Map<String, dynamic> toMap() => {
    'indiceOriginal': indiceOriginal,
    'indiceActual': indiceActual,
    'imagenUrl': imagenUrl,
  };

  factory PiezaPuzzle.fromMap(Map<String, dynamic> map) => PiezaPuzzle(
    indiceOriginal: map['indiceOriginal'] as int,
    indiceActual: map['indiceActual'] as int,
    imagenUrl: map['imagenUrl'] as String,
  );
}

/// Juego de puzzle con imágenes culturales
class Puzzle extends JuegoBase {
  final String imagenCompleta;    // URL de la imagen completa
  final List<PiezaPuzzle> piezas; // Piezas del puzzle
  final int filas;               // Dimensiones del puzzle
  final int columnas;
  final String descripcionImagen; // Descripción cultural de la imagen
  final int tiempoLimite;        // Tiempo límite en segundos
  final int movimientosMaximos;  // Movimientos permitidos
  
  const Puzzle({
    required super.id,
    required super.titulo,
    required super.descripcion,
    required this.imagenCompleta,
    required this.piezas,
    required this.filas,
    required this.columnas,
    required this.descripcionImagen,
    this.tiempoLimite = 300,     // 5 minutos por defecto
    this.movimientosMaximos = 100,
    required super.dificultad,
    required super.puntajeMaximo,
    super.categoriaId,
    super.categoriaNombre,
    super.activo = true,
    required super.fechaCreacion,
    required super.fechaActualizacion,
  }) : super(tipo: TipoJuego.puzzle);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo.value,
      'imagenCompleta': imagenCompleta,
      'piezas': piezas.map((p) => p.toMap()).toList(),
      'filas': filas,
      'columnas': columnas,
      'descripcionImagen': descripcionImagen,
      'tiempoLimite': tiempoLimite,
      'movimientosMaximos': movimientosMaximos,
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
  factory Puzzle.fromMap(Map<String, dynamic> map) {
    return Puzzle(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      imagenCompleta: map['imagenCompleta'] as String,
      piezas: (map['piezas'] as List)
          .map((p) => PiezaPuzzle.fromMap(p as Map<String, dynamic>))
          .toList(),
      filas: map['filas'] as int,
      columnas: map['columnas'] as int,
      descripcionImagen: map['descripcionImagen'] as String,
      tiempoLimite: map['tiempoLimite'] as int? ?? 300,
      movimientosMaximos: map['movimientosMaximos'] as int? ?? 100,
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
    if (respuesta is! List<int>) return false;
    if (respuesta.length != piezas.length) return false;

    // Verificar que cada pieza está en su posición original
    for (int i = 0; i < piezas.length; i++) {
      if (respuesta[i] != i) return false;
    }

    return true;
  }

  @override
  int calcularPuntaje(dynamic respuesta, Duration tiempoTranscurrido) {
    if (!validarRespuesta(respuesta)) return 0;
    if (tiempoTranscurrido.inSeconds > tiempoLimite) return 0;

    // Base: puntaje máximo
    int puntaje = puntajeMaximo;

    // Reducir por tiempo (máximo 30% de reducción)
    final segundos = tiempoTranscurrido.inSeconds;
    final reduccionTiempo = (segundos / tiempoLimite) * (puntaje * 0.3);
    
    puntaje -= reduccionTiempo.toInt();

    // Reducir por movimientos (20% máximo)
    final movimientos = (respuesta as Map)['movimientos'] as int;
    if (movimientos > movimientosMaximos) return 0;
    
    final reduccionMovimientos = (movimientos / movimientosMaximos) * (puntaje * 0.2);
    puntaje -= reduccionMovimientos.toInt();

    return puntaje.clamp(0, puntajeMaximo);
  }

  /// Verifica si un movimiento es válido
  bool esMovimientoValido(int indiceOrigen, int indiceDestino) {
    // Solo se pueden mover piezas adyacentes
    final origenFila = indiceOrigen ~/ columnas;
    final origenColumna = indiceOrigen % columnas;
    final destinoFila = indiceDestino ~/ columnas;
    final destinoColumna = indiceDestino % columnas;

    final distanciaFila = (origenFila - destinoFila).abs();
    final distanciaColumna = (origenColumna - destinoColumna).abs();

    // Solo permitir movimientos horizontales o verticales (no diagonales)
    return (distanciaFila == 1 && distanciaColumna == 0) ||
           (distanciaFila == 0 && distanciaColumna == 1);
  }
}
