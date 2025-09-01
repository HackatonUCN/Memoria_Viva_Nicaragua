import '../../entities/categoria.dart';
import '../../exceptions/categoria_exception.dart';
import '../../repositories/categoria_repository.dart';

/// Caso de uso para obtener todas las categorías
class ObtenerCategoriasUseCase {
  final ICategoriaRepository _categoriaRepository;

  ObtenerCategoriasUseCase(this._categoriaRepository);

  /// Obtiene todas las categorías activas
  /// 
  /// Throws:
  /// - [CategoriaException] si hay algún error durante el proceso
  Future<List<Categoria>> execute() async {
    try {
      return await _categoriaRepository.obtenerCategorias();
    } catch (e) {
      throw CategoriaException('Error al obtener categorías: $e');
    }
  }

  /// Stream que emite cambios en la lista de categorías
  Stream<List<Categoria>> observe() {
    return _categoriaRepository.observarCategorias();
  }
}
