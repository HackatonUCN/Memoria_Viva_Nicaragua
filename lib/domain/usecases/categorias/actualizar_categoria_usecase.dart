import '../../entities/categoria.dart';
import '../../exceptions/categoria_exception.dart';
import '../../repositories/categoria_repository.dart';

/// Caso de uso para actualizar una categoría existente
class ActualizarCategoriaUseCase {
  final ICategoriaRepository _categoriaRepository;

  ActualizarCategoriaUseCase(this._categoriaRepository);

  /// Actualiza una categoría existente
  /// 
  /// Throws:
  /// - [CategoriaNotFoundException] si la categoría no existe
  /// - [CategoriaDuplicadaException] si el nuevo nombre ya existe
  /// - [CategoriaException] si hay algún error durante el proceso
  Future<void> execute(Categoria categoria) async {
    try {
      // Verificar si la categoría existe
      final categoriaExistente = await _categoriaRepository.obtenerCategoriaPorId(categoria.id);
      if (categoriaExistente == null) {
        throw CategoriaNotFoundException();
      }

      // Si el nombre cambió, verificar que no exista otro igual
      if (categoriaExistente.nombre != categoria.nombre) {
        final categorias = await _categoriaRepository.obtenerCategoriasPorTipo(categoria.tipo);
        final existeNombre = categorias.any((c) => 
          c.id != categoria.id && 
          c.nombre.toLowerCase() == categoria.nombre.toLowerCase()
        );
        
        if (existeNombre) {
          throw CategoriaDuplicadaException();
        }
      }

      await _categoriaRepository.actualizarCategoria(categoria);
    } catch (e) {
      if (e is CategoriaNotFoundException || e is CategoriaDuplicadaException) {
        rethrow;
      }
      throw CategoriaException('Error al actualizar categoría: $e');
    }
  }
}
