import '../../entities/categoria.dart';
import '../../enums/tipos_contenido.dart';
import '../../exceptions/categoria_exception.dart';
import '../../repositories/categoria_repository.dart';

/// Caso de uso para obtener categorías filtradas por tipo
class ObtenerCategoriasPorTipoUseCase {
  final ICategoriaRepository _categoriaRepository;

  ObtenerCategoriasPorTipoUseCase(this._categoriaRepository);

  /// Obtiene las categorías de un tipo específico
  /// 
  /// [tipo] - El tipo de contenido (relato, saber, evento)
  /// 
  /// Throws:
  /// - [CategoriaException] si hay algún error durante el proceso
  Future<List<Categoria>> execute(TipoContenido tipo) async {
    try {
      return await _categoriaRepository.obtenerCategoriasPorTipo(tipo);
    } catch (e) {
      throw CategoriaException('Error al obtener categorías por tipo: $e');
    }
  }

  /// Stream que emite cambios en las categorías de un tipo específico
  Stream<List<Categoria>> observe(TipoContenido tipo) {
    return _categoriaRepository.observarCategorias()
        .map((categorias) => categorias.where((c) => c.tipo == tipo).toList());
  }
}
