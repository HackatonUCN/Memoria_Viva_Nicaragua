import '../entities/user.dart';
import '../entities/relato.dart';
import '../entities/saber_popular.dart';
import '../entities/evento_cultural.dart';

/// Interfaz para el servicio de analítica
abstract class IAnalyticsService {
  /// Inicializa el servicio con el usuario actual
  Future<void> inicializar({User? usuario});

  /// Registra un evento de visualización de contenido
  Future<void> registrarVisualizacion({
    required String contenidoId,
    required String tipoContenido,
    Map<String, dynamic>? propiedades,
  });

  /// Registra un evento de interacción (like, compartir, comentar)
  Future<void> registrarInteraccion({
    required String contenidoId,
    required String tipoContenido,
    required String tipoInteraccion,
    Map<String, dynamic>? propiedades,
  });

  /// Registra un evento de búsqueda
  Future<void> registrarBusqueda({
    required String consulta,
    required String tipoContenido,
    required int resultados,
    Map<String, dynamic>? filtros,
  });

  /// Registra un evento de navegación entre pantallas
  Future<void> registrarNavegacion({
    required String pantalla,
    String? pantallaAnterior,
    Map<String, dynamic>? propiedades,
  });

  /// Registra un evento de error
  Future<void> registrarError({
    required String mensaje,
    required String codigo,
    String? ubicacion,
    Map<String, dynamic>? contexto,
  });

  /// Registra un evento personalizado
  Future<void> registrarEvento({
    required String nombre,
    Map<String, dynamic>? propiedades,
  });

  /// Registra el inicio de una sesión de usuario
  Future<void> registrarInicioSesion({
    required String metodo,
    bool esNuevoUsuario = false,
  });

  /// Registra el cierre de una sesión de usuario
  Future<void> registrarCierreSesion({
    int duracionSesionSegundos,
  });

  /// Registra la creación de contenido
  Future<void> registrarCreacionContenido({
    required String tipoContenido,
    required String contenidoId,
    Map<String, dynamic>? propiedades,
  });

  /// Registra la participación en un evento cultural
  Future<void> registrarParticipacionEvento({
    required String eventoId,
    required String tipoParticipacion,
  });

  /// Registra el rendimiento de la aplicación
  Future<void> registrarRendimiento({
    required String operacion,
    required int duracionMs,
    Map<String, dynamic>? metricas,
  });

  /// Registra el uso de características específicas
  Future<void> registrarUsoCaracteristica({
    required String caracteristica,
    Map<String, dynamic>? propiedades,
  });

  /// Obtiene estadísticas de uso para un usuario
  Future<Map<String, dynamic>> obtenerEstadisticasUsuario(String usuarioId);

  /// Obtiene estadísticas de un contenido específico
  Future<Map<String, dynamic>> obtenerEstadisticasContenido({
    required String contenidoId,
    required String tipoContenido,
  });

  /// Obtiene las tendencias actuales (contenido popular)
  Future<List<Map<String, dynamic>>> obtenerTendencias({
    String? tipoContenido,
    int limite = 10,
  });

  /// Obtiene métricas de uso general de la aplicación
  Future<Map<String, dynamic>> obtenerMetricasAplicacion({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  });

  /// Establece propiedades de usuario para segmentación
  Future<void> establecerPropiedadesUsuario(Map<String, dynamic> propiedades);

  /// Desactiva el seguimiento para un usuario (privacidad)
  Future<void> desactivarSeguimiento();

  /// Activa el seguimiento para un usuario
  Future<void> activarSeguimiento();
}
