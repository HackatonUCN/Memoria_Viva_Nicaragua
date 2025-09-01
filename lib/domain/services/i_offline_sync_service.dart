import '../entities/relato.dart';
import '../entities/saber_popular.dart';
import '../entities/evento_cultural.dart';

/// Interfaz para el servicio de sincronización offline
abstract class IOfflineSyncService {
  /// Inicializa el servicio de sincronización
  Future<void> inicializar();

  /// Activa la funcionalidad offline
  Future<void> activarModoOffline();

  /// Desactiva la funcionalidad offline
  Future<void> desactivarModoOffline();

  /// Verifica si el modo offline está activo
  bool estaEnModoOffline();

  /// Verifica si hay conexión a Internet
  Future<bool> verificarConexion();

  /// Configura los tipos de contenido a sincronizar
  Future<void> configurarContenidoASincronizar(List<String> tiposContenido);

  /// Configura el límite de almacenamiento offline (en MB)
  Future<void> configurarLimiteAlmacenamiento(int limiteMB);

  /// Obtiene el espacio utilizado por el almacenamiento offline (en MB)
  Future<double> obtenerEspacioUtilizado();

  /// Sincroniza datos locales con el servidor cuando hay conexión
  Future<Map<String, dynamic>> sincronizarDatos();

  /// Guarda un relato localmente para sincronizar después
  Future<void> guardarRelatoOffline(Relato relato);

  /// Guarda un saber popular localmente para sincronizar después
  Future<void> guardarSaberOffline(SaberPopular saber);

  /// Guarda un evento cultural localmente para sincronizar después
  Future<void> guardarEventoOffline(EventoCultural evento);

  /// Guarda un comentario localmente para sincronizar después
  Future<void> guardarComentarioOffline({
    required String contenidoId,
    required String tipoContenido,
    required String texto,
  });

  /// Guarda una interacción localmente para sincronizar después
  Future<void> guardarInteraccionOffline({
    required String contenidoId,
    required String tipoContenido,
    required String tipoInteraccion,
  });

  /// Obtiene relatos guardados localmente
  Future<List<Relato>> obtenerRelatosOffline();

  /// Obtiene saberes populares guardados localmente
  Future<List<SaberPopular>> obtenerSaberesOffline();

  /// Obtiene eventos culturales guardados localmente
  Future<List<EventoCultural>> obtenerEventosOffline();

  /// Obtiene contenido pendiente de sincronización
  Future<Map<String, List<dynamic>>> obtenerContenidoPendiente();

  /// Elimina contenido guardado localmente
  Future<void> eliminarContenidoLocal({
    required String contenidoId,
    required String tipoContenido,
  });

  /// Limpia todo el contenido guardado localmente
  Future<void> limpiarContenidoLocal();

  /// Descarga contenido para uso offline según filtros
  Future<Map<String, int>> descargarContenido({
    List<String>? tiposContenido,
    String? departamento,
    String? municipio,
    int? limitePorTipo,
  });

  /// Configura sincronización automática
  Future<void> configurarSincronizacionAutomatica({
    required bool activa,
    int? intervaloMinutos,
    bool? soloWifi,
  });

  /// Obtiene el estado de sincronización
  Future<Map<String, dynamic>> obtenerEstadoSincronizacion();

  /// Registra un listener para cambios en el estado de sincronización
  void registrarListenerSincronizacion(Function(Map<String, dynamic>) callback);

  /// Elimina un listener de sincronización
  void eliminarListenerSincronizacion(Function(Map<String, dynamic>) callback);

  /// Resuelve conflictos de sincronización
  Future<void> resolverConflicto({
    required String contenidoId,
    required String tipoContenido,
    required bool usarVersionLocal,
  });

  /// Verifica si hay conflictos pendientes de resolución
  Future<List<Map<String, dynamic>>> verificarConflictosPendientes();

  /// Prioriza la sincronización de ciertos elementos
  Future<void> priorizarSincronizacion({
    required String contenidoId,
    required String tipoContenido,
  });

  /// Cancela la sincronización en curso
  Future<void> cancelarSincronizacion();

  /// Pausa la sincronización
  Future<void> pausarSincronizacion();

  /// Reanuda la sincronización
  Future<void> reanudarSincronizacion();
}
