import '../../exceptions/categoria_exception.dart';
import '../../repositories/categoria_repository.dart';

/// Caso de uso para eliminar una categoría
class EliminarCategoriaUseCase {
  final ICategoriaRepository _categoriaRepository;

  EliminarCategoriaUseCase(this._categoriaRepository);

  /// Elimina una categoría si no está siendo utilizada
  /// 
  /// [categoriaId] - ID de la categoría a eliminar
  /// 
  /// Throws:
  /// - [CategoriaNotFoundException] si la categoría no existe
  /// - [CategoriaEnUsoException] si la categoría está siendo utilizada
  /// - [CategoriaException] si hay algún error durante el proceso
  Future<void> execute(String categoriaId) async {
    try {
      // Verificar si la categoría existe
      final categoria = await _categoriaRepository.obtenerCategoriaPorId(categoriaId);
      if (categoria == null) {
        throw CategoriaNotFoundException();
      }

      // TODO: Verificar si la categoría está siendo utilizada en relatos, saberes o eventos
      // Esto requeriría inyectar los otros repositorios o crear un servicio específico

      await _categoriaRepository.eliminarCategoria(categoriaId);
    } catch (e) {
      if (e is CategoriaNotFoundException || e is CategoriaEnUsoException) {
        rethrow;
      }
      throw CategoriaException('Error al eliminar categoría: $e');
    }
  }
}
