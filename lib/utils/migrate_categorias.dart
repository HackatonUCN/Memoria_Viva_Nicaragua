import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../data/models/categoria_model.dart';
import '../domain/entities/categoria.dart';
import '../domain/enums/tipos_contenido.dart';

/// Clase para migrar categorías desde un archivo JSON a Firestore
class CategoriaMigrator {
  static const String _categoriasCollection = 'categorias';
  static const String _categoriasJsonPath = 'assets/config/categories_seed.json';

  /// Migra las categorías desde el archivo JSON a Firestore
  static Future<void> migrateCategorias({bool forceUpdate = false}) async {
    try {
      print('Iniciando migración de categorías...');
      
      // 1. Leer el JSON desde assets
      final List<Map<String, dynamic>> categoriasJson = await _leerCategoriasDesdeJson();
      print('Leídas ${categoriasJson.length} categorías desde JSON');
      
      // 2. Convertir a modelos de categoría
      final List<CategoriaModel> categorias = _convertirAModelos(categoriasJson);
      
      // 3. Subir a Firestore usando batch
      final resultados = await _subirAFirestore(categorias, forceUpdate: forceUpdate);
      
      // 4. Mostrar resultados
      print('Migración completada:');
      print('- Categorías existentes: ${resultados.existentes}');
      print('- Categorías actualizadas: ${resultados.actualizadas}');
      print('- Categorías nuevas: ${resultados.nuevas}');
      print('- Errores: ${resultados.errores}');
      
    } catch (e, stackTrace) {
      print('Error durante la migración de categorías: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Lee las categorías desde el archivo JSON en assets
  static Future<List<Map<String, dynamic>>> _leerCategoriasDesdeJson() async {
    try {
      // Leer el archivo JSON
      final String jsonString = await rootBundle.loadString(_categoriasJsonPath);
      
      // Decodificar el JSON
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      
      // Convertir a List<Map<String, dynamic>>
      return jsonList.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error al leer el archivo JSON: $e');
      rethrow;
    }
  }

  /// Convierte los datos JSON a modelos de categoría
  static List<CategoriaModel> _convertirAModelos(List<Map<String, dynamic>> categoriasJson) {
    final List<CategoriaModel> categorias = [];
    
    for (final categoriaJson in categoriasJson) {
      try {
        // Crear la entidad de dominio primero
        final categoria = Categoria(
          id: categoriaJson['id'] as String,
          nombre: categoriaJson['nombre'] as String,
          descripcion: categoriaJson['descripcion'] as String,
          tipo: TipoContenido.fromString(categoriaJson['tipo'] as String),
          icono: categoriaJson['icono'] as String,
          color: categoriaJson['color'] as String,
          orden: categoriaJson['orden'] as int,
          activa: categoriaJson['activa'] as bool? ?? true,
          categoriaPadreId: categoriaJson['categoriaPadreId'] as String?,
          fechaCreacion: DateTime.now().toUtc(),
          fechaActualizacion: DateTime.now().toUtc(),
        );
        
        // Convertir a modelo para Firestore
        final categoriaModel = CategoriaModel.fromDomain(categoria);
        categorias.add(categoriaModel);
      } catch (e) {
        print('Error al convertir categoría: ${categoriaJson['id']} - $e');
      }
    }
    
    return categorias;
  }

  /// Sube las categorías a Firestore usando batch writes
  static Future<MigracionResultados> _subirAFirestore(
    List<CategoriaModel> categorias, {
    bool forceUpdate = false,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference categoriasRef = firestore.collection(_categoriasCollection);
    
    int existentes = 0;
    int actualizadas = 0;
    int nuevas = 0;
    int errores = 0;
    
    // Crear un batch para operaciones múltiples
    WriteBatch batch = firestore.batch();
    int operacionesEnBatch = 0;
    
    for (final categoria in categorias) {
      try {
        // Verificar si la categoría ya existe
        final docRef = categoriasRef.doc(categoria.id);
        final docSnapshot = await docRef.get();
        
        if (docSnapshot.exists) {
          // La categoría ya existe
          if (forceUpdate) {
            // Actualizar si se fuerza la actualización
            batch.set(docRef, categoria.toMap());
            actualizadas++;
          } else {
            // No actualizar si no se fuerza
            existentes++;
          }
        } else {
          // Crear nueva categoría
          batch.set(docRef, categoria.toMap());
          nuevas++;
        }
        
        // Incrementar contador de operaciones
        operacionesEnBatch++;
        
        // Commit batch cada 500 operaciones (límite de Firestore)
        if (operacionesEnBatch >= 500) {
          await batch.commit();
          batch = firestore.batch();
          operacionesEnBatch = 0;
        }
      } catch (e) {
        if (e.toString().contains('permission-denied')) {
          print('Error de permisos al procesar categoría ${categoria.id}: $e');
          print('SOLUCIÓN: Verifica que estás autenticado como administrador o modifica temporalmente las reglas de Firestore.');
          print('Consulta lib/utils/README_migracion_categorias.md para instrucciones detalladas.');
        } else {
          print('Error al procesar categoría ${categoria.id}: $e');
        }
        errores++;
      }
    }
    
    // Commit final si quedan operaciones pendientes
    if (operacionesEnBatch > 0) {
      await batch.commit();
    }
    
    return MigracionResultados(
      existentes: existentes,
      actualizadas: actualizadas,
      nuevas: nuevas,
      errores: errores,
    );
  }
}

/// Clase para almacenar los resultados de la migración
class MigracionResultados {
  final int existentes;
  final int actualizadas;
  final int nuevas;
  final int errores;
  
  MigracionResultados({
    required this.existentes,
    required this.actualizadas,
    required this.nuevas,
    required this.errores,
  });
}
