import '../entities/saber_popular.dart';
import '../enums/estado_moderacion.dart';

/// Repositorio para manejar los saberes populares en la aplicación
abstract class ISaberPopularRepository {
  /// Obtiene todos los saberes populares activos
  Future<List<SaberPopular>> obtenerSaberes();

  /// Obtiene un saber popular específico por su ID
  Future<SaberPopular?> obtenerSaberPorId(String id);

  /// Obtiene saberes por categoría
  Future<List<SaberPopular>> obtenerSaberesPorCategoria(String categoriaId);

  /// Obtiene saberes por autor
  Future<List<SaberPopular>> obtenerSaberesPorAutor(String autorId);

  /// Obtiene saberes por ubicación
  Future<List<SaberPopular>> obtenerSaberesPorUbicacion({
    String? departamento,
    String? municipio,
  });

  /// Guarda un nuevo saber popular
  Future<void> guardarSaber(SaberPopular saber);

  /// Actualiza un saber popular existente
  Future<void> actualizarSaber(SaberPopular saber);

  /// Elimina un saber popular (soft delete)
  Future<void> eliminarSaber(String id);

  /// Restaura un saber popular eliminado
  Future<void> restaurarSaber(String id);

  /// Reporta un saber popular
  Future<void> reportarSaber(String id, String razon);

  /// Modera un saber popular
  Future<void> moderarSaber(String id, EstadoModeracion estado);

  /// Incrementa el contador de likes
  Future<void> darLike(String id);

  /// Incrementa el contador de compartidos
  Future<void> registrarCompartido(String id);

  /// Stream para observar cambios en los saberes en tiempo real
  Stream<List<SaberPopular>> observarSaberes();

  /// Stream para observar cambios en un saber específico
  Stream<SaberPopular?> observarSaberPorId(String id);

  /// Stream para observar saberes por categoría
  Stream<List<SaberPopular>> observarSaberesPorCategoria(String categoriaId);

  /// Busca saberes por texto
  Future<List<SaberPopular>> buscarSaberes(String texto);

  /// Busca saberes similares (para evitar duplicados)
  Future<List<SaberPopular>> buscarSaberesSimilares({
    required String titulo,
    required String categoriaId,
  });
}