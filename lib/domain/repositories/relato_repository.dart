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

  /// Reporta un relato
  Future<void> reportarRelato(String id, String razon);

  /// Modera un relato (aprobar/ocultar)
  Future<void> moderarRelato(String id, EstadoModeracion estado);

  /// Incrementa el contador de likes
  Future<void> darLike(String id);

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
}