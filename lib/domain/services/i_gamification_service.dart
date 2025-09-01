import '../entities/user.dart';

/// Interfaz para el servicio de gamificación
abstract class IGamificationService {
  /// Inicializa el servicio para un usuario
  Future<void> inicializar(String userId);

  /// Otorga puntos a un usuario por una acción específica
  Future<int> otorgarPuntos({
    required String userId,
    required String accion,
    int? puntos,
    String? descripcion,
  });

  /// Otorga una insignia a un usuario
  Future<void> otorgarInsignia({
    required String userId,
    required String insigniaId,
    String? razon,
  });

  /// Verifica si un usuario ha completado un logro
  Future<bool> verificarLogro({
    required String userId,
    required String logroId,
    Map<String, dynamic>? parametros,
  });

  /// Registra progreso hacia un logro
  Future<double> registrarProgresoLogro({
    required String userId,
    required String logroId,
    required double progreso,
  });

  /// Registra una acción del usuario
  Future<void> registrarAccion({
    required String userId,
    required String accion,
    Map<String, dynamic>? metadatos,
  });

  /// Obtiene el nivel actual del usuario
  Future<int> obtenerNivel(String userId);

  /// Obtiene los puntos totales del usuario
  Future<int> obtenerPuntos(String userId);

  /// Obtiene las insignias del usuario
  Future<List<Map<String, dynamic>>> obtenerInsignias(String userId);

  /// Obtiene los logros del usuario con su progreso
  Future<List<Map<String, dynamic>>> obtenerLogros(String userId);

  /// Obtiene el historial de acciones del usuario
  Future<List<Map<String, dynamic>>> obtenerHistorialAcciones({
    required String userId,
    int limite = 50,
    int pagina = 1,
  });

  /// Obtiene la posición del usuario en la tabla de clasificación
  Future<Map<String, dynamic>> obtenerPosicionRanking(String userId);

  /// Obtiene la tabla de clasificación general o por categoría
  Future<List<Map<String, dynamic>>> obtenerTablaClasificacion({
    String? categoria,
    int limite = 10,
  });

  /// Verifica y otorga logros pendientes
  Future<List<String>> verificarLogrosDisponibles(String userId);

  /// Obtiene recomendaciones de acciones para subir de nivel
  Future<List<Map<String, dynamic>>> obtenerRecomendaciones(String userId);

  /// Obtiene estadísticas de gamificación del usuario
  Future<Map<String, dynamic>> obtenerEstadisticas(String userId);

  /// Reinicia el progreso de un logro específico
  Future<void> reiniciarProgresoLogro({
    required String userId,
    required String logroId,
  });

  /// Configura las preferencias de gamificación del usuario
  Future<void> configurarPreferencias({
    required String userId,
    required Map<String, dynamic> preferencias,
  });

  /// Obtiene las preferencias de gamificación del usuario
  Future<Map<String, dynamic>> obtenerPreferencias(String userId);

  /// Verifica si un usuario ha completado un desafío diario
  Future<bool> verificarDesafioDiario({
    required String userId,
    required String desafioId,
  });

  /// Obtiene los desafíos diarios disponibles
  Future<List<Map<String, dynamic>>> obtenerDesafiosDiarios(String userId);

  /// Registra la finalización de un desafío diario
  Future<void> completarDesafioDiario({
    required String userId,
    required String desafioId,
  });

  /// Genera un nuevo conjunto de desafíos diarios
  Future<List<Map<String, dynamic>>> generarDesafiosDiarios(String userId);

  /// Obtiene las estadísticas de contribución cultural del usuario
  Future<Map<String, dynamic>> obtenerEstadisticasContribucion(String userId);

  /// Calcula el nivel de experticia en una categoría específica
  Future<Map<String, dynamic>> calcularExperticia({
    required String userId,
    required String categoria,
  });
}
