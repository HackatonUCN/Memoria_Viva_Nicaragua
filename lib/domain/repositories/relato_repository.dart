import '../entities/relato.dart';
import '../enums/estado_moderacion.dart';

/// Repositorio para manejar los relatos en la aplicación
abstract class IRelatoRepository {
  /// Obtiene todos los relatos activos
  Future<List<Relato>> obtenerRelatos();

  /// Obtiene un relato específico por su ID
  Future<Relato?> obtenerRelatoPorId(String id);

  /// Obtiene relatos por categoría
  Future<List<Relato>> obtenerRelatosPorCategoria(String categoriaId);

  /// Obtiene relatos por autor
  Future<List<Relato>> obtenerRelatosPorAutor(String autorId);

  /// Obtiene relatos por ubicación (departamento/municipio)
  Future<List<Relato>> obtenerRelatosPorUbicacion({
    String? departamento,
    String? municipio,
  });

  /// Guarda un nuevo relato
  Future<void> guardarRelato(Relato relato);

  /// Actualiza un relato existente
  Future<void> actualizarRelato(Relato relato);

  /// Elimina un relato (soft delete)
  Future<void> eliminarRelato(String id);

  /// Restaura un relato eliminado
  Future<void> restaurarRelato(String id);

  /// Reporta un relato (idempotente por usuario)
  Future<bool> reportarRelato(String id, String razon, {required String userId});

  /// Modera un relato (aprobar/ocultar)
  Future<void> moderarRelato(String id, EstadoModeracion estado);

  /// Toggle de like idempotente por usuario; retorna true si quedó en like
  Future<bool> toggleLike({required String id, required String userId});

  /// Incrementa el contador de compartidos
  Future<void> registrarCompartido(String id);

  /// Stream para observar cambios en los relatos en tiempo real
  Stream<List<Relato>> observarRelatos();

  /// Stream para observar cambios en un relato específico
  Stream<Relato?> observarRelatoPorId(String id);

  /// Stream para observar relatos por categoría
  Stream<List<Relato>> observarRelatosPorCategoria(String categoriaId);

  /// Busca relatos por texto
  Future<List<Relato>> buscarRelatos(String texto);

  /// Obtiene relatos cercanos a una ubicación
  Future<List<Relato>> obtenerRelatosCercanos({
    required double latitud,
    required double longitud,
    required double radioKm,
  });

  /// Busca relatos similares (para evitar duplicados)
  Future<List<Relato>> buscarRelatosSimilares({
    required String titulo,
    required String autorId,
  });

  /// Obtiene relatos dentro de un bounding box (sur, oeste, norte, este)
  /// Solo retornará relatos activos y no eliminados. Implícitamente requiere ubicación.
  Future<List<Relato>> obtenerRelatosEnBounds({
    required double south,
    required double west,
    required double north,
    required double east,
    int limit = 200,
  });
}