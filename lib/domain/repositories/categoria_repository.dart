import '../entities/categoria.dart';
import '../enums/tipos_contenido.dart';

/// Repositorio para manejar las categorías en la aplicación
abstract class ICategoriaRepository {
  /// Obtiene todas las categorías
  Future<List<Categoria>> obtenerCategorias();

  /// Obtiene categorías filtradas por tipo de contenido
  Future<List<Categoria>> obtenerCategoriasPorTipo(TipoContenido tipo);

  /// Obtiene una categoría específica por su ID
  Future<Categoria?> obtenerCategoriaPorId(String id);

  /// Guarda una nueva categoría
  Future<void> guardarCategoria(Categoria categoria);

  /// Actualiza una categoría existente
  Future<void> actualizarCategoria(Categoria categoria);

  /// Elimina una categoría
  Future<void> eliminarCategoria(String id);

  /// Obtiene las subcategorías de una categoría padre
  Future<List<Categoria>> obtenerSubcategorias(String categoriaPadreId);

  /// Stream para observar cambios en las categorías en tiempo real
  Stream<List<Categoria>> observarCategorias();

  /// Stream para observar cambios en una categoría específica
  Stream<Categoria?> observarCategoriaPorId(String id);
}
