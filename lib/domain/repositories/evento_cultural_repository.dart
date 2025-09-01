import '../entities/evento_cultural.dart';
import '../enums/tipos_evento.dart';

/// Repositorio para manejar los eventos culturales en la aplicación
abstract class IEventoCulturalRepository {
  // Eventos Oficiales
  
  /// Obtiene todos los eventos activos
  Future<List<EventoCultural>> obtenerEventos();

  /// Obtiene un evento específico por su ID
  Future<EventoCultural?> obtenerEventoPorId(String id);

  /// Obtiene eventos por categoría
  Future<List<EventoCultural>> obtenerEventosPorCategoria(String categoriaId);

  /// Obtiene eventos por tipo
  Future<List<EventoCultural>> obtenerEventosPorTipo(TipoEvento tipo);

  /// Obtiene eventos por fecha
  Future<List<EventoCultural>> obtenerEventosPorFecha(DateTime fecha);

  /// Obtiene eventos por rango de fechas
  Future<List<EventoCultural>> obtenerEventosPorRangoFecha({
    required DateTime inicio,
    required DateTime fin,
  });

  /// Obtiene eventos por ubicación
  Future<List<EventoCultural>> obtenerEventosPorUbicacion({
    String? departamento,
    String? municipio,
  });

  /// Guarda un nuevo evento
  Future<void> guardarEvento(EventoCultural evento);

  /// Actualiza un evento existente
  Future<void> actualizarEvento(EventoCultural evento);

  /// Elimina un evento (soft delete)
  Future<void> eliminarEvento(String id);

  /// Restaura un evento eliminado
  Future<void> restaurarEvento(String id);

  /// Stream para observar cambios en los eventos en tiempo real
  Stream<List<EventoCultural>> observarEventos();

  /// Stream para observar cambios en un evento específico
  Stream<EventoCultural?> observarEventoPorId(String id);

  /// Stream para observar eventos por categoría
  Stream<List<EventoCultural>> observarEventosPorCategoria(String categoriaId);

  // Sugerencias de Eventos

  /// Obtiene todas las sugerencias pendientes
  Future<List<SugerenciaEvento>> obtenerSugerenciasPendientes();

  /// Obtiene sugerencias por usuario
  Future<List<SugerenciaEvento>> obtenerSugerenciasPorUsuario(String usuarioId);

  /// Obtiene una sugerencia específica
  Future<SugerenciaEvento?> obtenerSugerenciaPorId(String id);

  /// Guarda una nueva sugerencia
  Future<void> guardarSugerencia(SugerenciaEvento sugerencia);

  /// Aprueba una sugerencia y crea el evento
  Future<void> aprobarSugerencia({
    required String sugerenciaId,
    required String adminId,
  });

  /// Rechaza una sugerencia
  Future<void> rechazarSugerencia({
    required String sugerenciaId,
    required String razon,
    required String adminId,
  });

  /// Stream para observar sugerencias pendientes
  Stream<List<SugerenciaEvento>> observarSugerenciasPendientes();

  /// Stream para observar sugerencias de un usuario
  Stream<List<SugerenciaEvento>> observarSugerenciasPorUsuario(String usuarioId);

  /// Busca eventos por texto
  Future<List<EventoCultural>> buscarEventos(String texto);

  /// Obtiene eventos cercanos a una ubicación
  Future<List<EventoCultural>> obtenerEventosCercanos({
    required double latitud,
    required double longitud,
    required double radioKm,
  });
}
