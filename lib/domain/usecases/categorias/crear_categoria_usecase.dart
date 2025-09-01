import '../../entities/categoria.dart';
import '../../exceptions/categoria_exception.dart';
import '../../repositories/categoria_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para crear una nueva categoría
class CrearCategoriaUseCase {
  final ICategoriaRepository _categoriaRepository;

  CrearCategoriaUseCase(this._categoriaRepository);

  /// Crea una nueva categoría
  /// 
  /// Throws:
  /// - [CategoriaDuplicadaException] si ya existe una categoría con el mismo nombre
  /// - [CategoriaException] si hay algún error durante el proceso
  UseCaseResult<void> execute(Categoria categoria) async {
    try {
      // Obtener categorías existentes para verificar duplicados
      final categorias = await _categoriaRepository.obtenerCategoriasPorTipo(categoria.tipo);
      
      // Verificar si ya existe una categoría con el mismo nombre
      final existeNombre = categorias.any((c) => 
        c.nombre.toLowerCase() == categoria.nombre.toLowerCase());
      
      if (existeNombre) {
        throw CategoriaDuplicadaException();
      }

      await _categoriaRepository.guardarCategoria(categoria);
      return Success<void, Failure>(null);
    } catch (e) {
      return FailureResult<void, Failure>(mapExceptionToFailure(e));
    }
  }
}
