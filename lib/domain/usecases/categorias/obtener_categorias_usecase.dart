import '../../entities/categoria.dart';
import '../../exceptions/categoria_exception.dart';
import '../../repositories/categoria_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para obtener todas las categorías
class ObtenerCategoriasUseCase {
  final ICategoriaRepository _categoriaRepository;

  ObtenerCategoriasUseCase(this._categoriaRepository);

  /// Obtiene todas las categorías activas
  /// 
  /// Throws:
  /// - [CategoriaException] si hay algún error durante el proceso
  UseCaseResult<List<Categoria>> execute() async {
    try {
      final data = await _categoriaRepository.obtenerCategorias();
      return Success<List<Categoria>, Failure>(data);
    } catch (e) {
      return FailureResult<List<Categoria>, Failure>(mapExceptionToFailure(CategoriaException('Error al obtener categorías: $e')));
    }
  }

  /// Stream que emite cambios en la lista de categorías
  Stream<List<Categoria>> observe() {
    return _categoriaRepository.observarCategorias();
  }
}
