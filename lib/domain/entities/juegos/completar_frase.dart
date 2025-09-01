import 'juego_base.dart';
import '../../enums/tipos_juego.dart';

/// Juego de completar frases o dichos
class CompletarFrase extends JuegoBase {
  final String fraseIncompleta;    // Frase con placeholder (ej: "Más vale pájaro en mano que ___ volando")
  final String parteCorrecta;      // Parte que completa la frase
  final List<String> opciones;     // Opciones para elegir (incluye la correcta)
  final String? contexto;          // Explicación del significado o contexto
  
  const CompletarFrase({
    required super.id,
    required super.titulo,
    required super.descripcion,
    required this.fraseIncompleta,
    required this.parteCorrecta,
    required this.opciones,
    this.contexto,
    required super.dificultad,
    required super.puntajeMaximo,
    super.categoriaId,
    super.categoriaNombre,
    super.activo = true,
    required super.fechaCreacion,
    required super.fechaActualizacion,
  }) : super(tipo: TipoJuego.completar_frase);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo.value,
      'fraseIncompleta': fraseIncompleta,
      'parteCorrecta': parteCorrecta,
      'opciones': opciones,
      'contexto': contexto,
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
  factory CompletarFrase.fromMap(Map<String, dynamic> map) {
    return CompletarFrase(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      fraseIncompleta: map['fraseIncompleta'] as String,
      parteCorrecta: map['parteCorrecta'] as String,
      opciones: List<String>.from(map['opciones'] ?? []),
      contexto: map['contexto'] as String?,
      dificultad: NivelDificultad.values.firstWhere(
        (d) => d.value == map['dificultad'],
        orElse: () => NivelDificultad.facil,
      ),
      puntajeMaximo: map['puntajeMaximo'] as int,
      categoriaId: map['categoriaId'] as String?,
      categoriaNombre: map['categoriaNombre'] as String?,
      activo: map['activo'] as bool? ?? true,
      fechaCreacion: _parseDateTime(map['fechaCreacion']),
      fechaActualizacion: _parseDateTime(map['fechaActualizacion']),
    );
  }

  @override
  bool validarRespuesta(dynamic respuesta) {
    if (respuesta is! String) return false;
    return respuesta.trim().toLowerCase() == parteCorrecta.toLowerCase();
  }

  @override
  int calcularPuntaje(dynamic respuesta, Duration tiempoTranscurrido) {
    if (!validarRespuesta(respuesta)) return 0;

    // Base: puntaje máximo
    int puntaje = puntajeMaximo;

    // Reducir por tiempo (máximo 30% de reducción)
    final segundos = tiempoTranscurrido.inSeconds;
    final reduccionTiempo = (segundos > 30) 
        ? puntaje * 0.3 
        : (segundos / 30) * (puntaje * 0.3);
    
    puntaje -= reduccionTiempo.toInt();

    return puntaje.clamp(0, puntajeMaximo);
  }

  /// Obtiene la frase completa con la respuesta correcta
  String getFraseCompleta() {
    return fraseIncompleta.replaceAll('___', parteCorrecta);
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  if (value is DateTime) {
    return value.isUtc ? value : value.toUtc();
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  }
  if (value is String) {
    return DateTime.parse(value).toUtc();
  }
  try {
    final dynamic dyn = value;
    final DateTime dt = dyn.toDate();
    return dt.isUtc ? dt : dt.toUtc();
  } catch (_) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
