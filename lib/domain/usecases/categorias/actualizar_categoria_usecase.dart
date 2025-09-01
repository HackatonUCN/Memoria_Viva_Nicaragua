import '../../entities/categoria.dart';
import '../../exceptions/categoria_exception.dart';
import '../../repositories/categoria_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

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
  UseCaseResult<void> execute(Categoria categoria) async {
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
      return Success<void, Failure>(null);
    } catch (e) {
      return FailureResult<void, Failure>(mapExceptionToFailure(e));
    }
  }
}
