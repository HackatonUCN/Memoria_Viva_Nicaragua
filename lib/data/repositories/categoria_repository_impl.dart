import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/exception.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/enums/tipos_contenido.dart';
import '../../domain/exceptions/categoria_exception.dart';
import '../../domain/repositories/categoria_repository.dart';
import '../datasources/firestore_datasource.dart';
import '../models/categoria_model.dart';

/// Implementación del repositorio de categorías
class CategoriaRepositoryImpl implements ICategoriaRepository {
  final FirestoreDataSource<CategoriaModel> _dataSource;
  
  // Colección de categorías en Firestore
  static const String _categoriasCollection = 'categorias';

  CategoriaRepositoryImpl({
    required FirestoreDataSource<CategoriaModel> dataSource,
  }) : _dataSource = dataSource;

  /// Maneja las excepciones de las fuentes de datos y las convierte a excepciones de dominio
  Future<T> _handleExceptions<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DatabaseException catch (e) {
      throw CategoriaException(
        'Error en la base de datos: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      if (e is CategoriaException) rethrow;
      throw CategoriaException('Error inesperado: $e');
    }
  }

  @override
  Future<List<Categoria>> obtenerCategorias() async {
    return await _handleExceptions(() async {
      final categorias = await _dataSource.getAll(
        // Ordenar por orden ascendente y luego por nombre
        orderBy: 'orden',
      );
      
      return categorias.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Future<List<Categoria>> obtenerCategoriasPorTipo(TipoContenido tipo) async {
    return await _handleExceptions(() async {
      final categorias = await _dataSource.getWhere(
        field: 'tipo',
        isEqualTo: tipo.value,
        orderBy: 'orden',
      );
      
      return categorias.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Future<Categoria?> obtenerCategoriaPorId(String id) async {
    return await _handleExceptions(() async {
      final categoria = await _dataSource.getById(id);
      return categoria?.toDomain();
    });
  }

  @override
  Future<void> guardarCategoria(Categoria categoria) async {
    return await _handleExceptions(() async {
      // Verificar si ya existe una categoría con el mismo nombre y tipo
      final existentes = await _dataSource.getWhere(
        field: 'nombre',
        isEqualTo: categoria.nombre,
      );
      
      final duplicados = existentes.where(
        (model) => 
            model.tipo == categoria.tipo.value && 
            model.id != categoria.id
      ).toList();
      
      if (duplicados.isNotEmpty) {
        throw CategoriaDuplicadaException.withName(
          nombre: categoria.nombre,
          tipo: categoria.tipo.value,
        );
      }
      
      // Validar los campos
      _validarCategoria(categoria);
      
      // Convertir y guardar
      final categoriaModel = CategoriaModel.fromDomain(categoria);
      await _dataSource.save(categoriaModel);
    });
  }

  @override
  Future<void> actualizarCategoria(Categoria categoria) async {
    return await _handleExceptions(() async {
      // Verificar que exista
      final existente = await _dataSource.getById(categoria.id);
      if (existente == null) {
        throw CategoriaNotFoundException.withId(categoria.id);
      }
      
      // Verificar duplicados de nombre
      final categoriasMismoNombre = await _dataSource.getWhere(
        field: 'nombre',
        isEqualTo: categoria.nombre,
      );
      
      final duplicados = categoriasMismoNombre.where(
        (model) => 
            model.tipo == categoria.tipo.value && 
            model.id != categoria.id
      ).toList();
      
      if (duplicados.isNotEmpty) {
        throw CategoriaDuplicadaException.withName(
          nombre: categoria.nombre,
          tipo: categoria.tipo.value,
        );
      }
      
      // Validar los campos
      _validarCategoria(categoria);
      
      // Convertir y guardar
      final categoriaModel = CategoriaModel.fromDomain(categoria);
      await _dataSource.save(categoriaModel);
    });
  }

  @override
  Future<void> eliminarCategoria(String id) async {
    return await _handleExceptions(() async {
      // Verificar que exista
      final categoria = await _dataSource.getById(id);
      if (categoria == null) {
        throw CategoriaNotFoundException.withId(id);
      }
      
      // Verificar si tiene subcategorías
      final subcategorias = await _dataSource.getWhere(
        field: 'categoriaPadreId',
        isEqualTo: id,
      );
      
      if (subcategorias.isNotEmpty) {
        throw CategoriaHierarchyException.withSubcategories(
          id: id, 
          cantidad: subcategorias.length,
        );
      }
      
      // TODO: Verificar si tiene contenido asociado (relatos, saberes, eventos)
      // Esta verificación requeriría consultas a otras colecciones
      
      // Eliminar
      await _dataSource.delete(id);
    });
  }

  @override
  Future<List<Categoria>> obtenerSubcategorias(String categoriaPadreId) async {
    return await _handleExceptions(() async {
      final subcategorias = await _dataSource.getWhere(
        field: 'categoriaPadreId',
        isEqualTo: categoriaPadreId,
        orderBy: 'orden',
      );
      
      return subcategorias.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Stream<List<Categoria>> observarCategorias() {
    try {
      return _dataSource.watchCollection(
        orderBy: 'orden',
      ).map((list) => list.map((model) => model.toDomain()).toList());
    } catch (e) {
      throw CategoriaException('Error al observar categorías: $e');
    }
  }

  @override
  Stream<Categoria?> observarCategoriaPorId(String id) {
    try {
      return _dataSource.watchDocument(id)
          .map((model) => model?.toDomain());
    } catch (e) {
      throw CategoriaException('Error al observar categoría: $e');
    }
  }
  
  /// Validaciones adicionales para categorías
  void _validarCategoria(Categoria categoria) {
    // Validar que el nombre no esté vacío
    if (categoria.nombre.trim().isEmpty) {
      throw CategoriaValidationException.field(
        campo: 'nombre',
        razon: 'El nombre no puede estar vacío',
      );
    }
    
    // Validar longitud de nombre
    if (categoria.nombre.length < 2 || categoria.nombre.length > 50) {
      throw CategoriaValidationException.field(
        campo: 'nombre',
        razon: 'El nombre debe tener entre 2 y 50 caracteres',
      );
    }
    
    // Validar descripción
    if (categoria.descripcion.trim().isEmpty) {
      throw CategoriaValidationException.field(
        campo: 'descripcion',
        razon: 'La descripción no puede estar vacía',
      );
    }
    
    // Validar formato de color
    if (categoria.color.startsWith('#')) {
      if (categoria.color.length != 7 && categoria.color.length != 9) {
        throw CategoriaValidationException.field(
          campo: 'color',
          razon: 'El formato de color hexadecimal es inválido',
        );
      }
    }
    
    // Validar orden
    if (categoria.orden < 0) {
      throw CategoriaValidationException.field(
        campo: 'orden',
        razon: 'El orden debe ser un número positivo',
      );
    }
  }
}