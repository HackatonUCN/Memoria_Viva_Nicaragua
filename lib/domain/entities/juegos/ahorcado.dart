import 'package:cloud_firestore/cloud_firestore.dart';
import '../../enums/tipos_juego.dart';
import 'juego_base.dart';

/// Juego del ahorcado
class Ahorcado extends JuegoBase {
  final String palabra;           // Palabra a adivinar
  final String pista;            // Pista sobre la palabra
  final int intentosMaximos;     // Intentos permitidos (típicamente 6)
  final List<String> letrasValidas; // Letras permitidas (ej: sin números)
  final String? contexto;        // Explicación cultural de la palabra
  
  const Ahorcado({
    required super.id,
    required super.titulo,
    required super.descripcion,
    required this.palabra,
    required this.pista,
    this.intentosMaximos = 6,
    this.letrasValidas = const ['A','B','C','D','E','F','G','H','I','J','K','L','M',
                               'N','Ñ','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
    this.contexto,
    required super.dificultad,
    required super.puntajeMaximo,
    super.categoriaId,
    super.categoriaNombre,
    super.activo = true,
    required super.fechaCreacion,
    required super.fechaActualizacion,
  }) : super(tipo: TipoJuego.ahorcado);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo.value,
      'palabra': palabra,
      'pista': pista,
      'intentosMaximos': intentosMaximos,
      'letrasValidas': letrasValidas,
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
  factory Ahorcado.fromMap(Map<String, dynamic> map) {
    return Ahorcado(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      palabra: map['palabra'] as String,
      pista: map['pista'] as String,
      intentosMaximos: map['intentosMaximos'] as int? ?? 6,
      letrasValidas: List<String>.from(map['letrasValidas'] ?? []),
      contexto: map['contexto'] as String?,
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
    return respuesta.trim().toUpperCase() == palabra.toUpperCase();
  }

  /// Valida si una letra está en la palabra
  bool validarLetra(String letra) {
    return palabra.toUpperCase().contains(letra.toUpperCase());
  }

  /// Obtiene las posiciones de una letra en la palabra
  List<int> obtenerPosicionesLetra(String letra) {
    final letraMayuscula = letra.toUpperCase();
    final palabraMayuscula = palabra.toUpperCase();
    List<int> posiciones = [];
    
    for (int i = 0; i < palabraMayuscula.length; i++) {
      if (palabraMayuscula[i] == letraMayuscula) {
        posiciones.add(i);
      }
    }
    
    return posiciones;
  }

  @override
  int calcularPuntaje(dynamic respuesta, Duration tiempoTranscurrido) {
    if (!validarRespuesta(respuesta)) return 0;

    // Base: puntaje máximo
    int puntaje = puntajeMaximo;

    // Reducir por tiempo (máximo 30% de reducción)
    final segundos = tiempoTranscurrido.inSeconds;
    final reduccionTiempo = (segundos > 180) 
        ? puntaje * 0.3 
        : (segundos / 180) * (puntaje * 0.3);
    
    puntaje -= reduccionTiempo.toInt();

    // Reducir por intentos fallidos (10% por intento)
    final intentosFallidos = (respuesta as Map)['intentosFallidos'] as int;
    final reduccionIntentos = (puntaje * 0.1) * intentosFallidos;
    
    puntaje -= reduccionIntentos.toInt();

    return puntaje.clamp(0, puntajeMaximo);
  }
}
