import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/exception.dart';
import '../firestore_datasource.dart';

/// Implementación genérica de FirestoreDataSource
class FirestoreDataSourceImpl<T> implements FirestoreDataSource<T> {
  final FirebaseFirestore _firestore;
  final String _collectionPath;
  final T Function(Map<String, dynamic>) _fromMap;
  final Map<String, dynamic> Function(T) _toMap;
  final String Function(T) _getId;

  FirestoreDataSourceImpl({
    required String collectionPath,
    required T Function(Map<String, dynamic>) fromMap,
    required Map<String, dynamic> Function(T) toMap,
    required String Function(T) getId,
    FirebaseFirestore? firestore,
  })  : _collectionPath = collectionPath,
        _fromMap = fromMap,
        _toMap = toMap,
        _getId = getId,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  String get collectionPath => _collectionPath;

  @override
  Future<T?> getById(String id) async {
    try {
      final docSnapshot = await _firestore.collection(_collectionPath).doc(id).get();
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return null;
      }
      return _fromMap(docSnapshot.data()!);
    } on FirebaseException catch (e) {
      throw DatabaseException(
        message: 'Error al obtener documento: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error inesperado al obtener documento: $e',
      );
    }
  }

  @override
  Future<List<T>> getAll({
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      Query query = _firestore.collection(_collectionPath);
      
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => _fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        message: 'Error al obtener documentos: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error inesperado al obtener documentos: $e',
      );
    }
  }

  @override
  Future<List<T>> getWhere({
    required String field,
    required dynamic isEqualTo,
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      Query query = _firestore.collection(_collectionPath).where(field, isEqualTo: isEqualTo);
      
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => _fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        message: 'Error al obtener documentos con filtro: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error inesperado al obtener documentos con filtro: $e',
      );
    }
  }

  @override
  Future<List<T>> query({
    required Map<String, dynamic> filters,
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      Query query = _firestore.collection(_collectionPath);
      
      // Aplicar todos los filtros
      filters.forEach((key, value) {
        if (value is List && value.length >= 3) {
          // Asumimos formato [campo, operador, valor]
          final field = value[0] as String;
          final operator = value[1] as String;
          final filterValue = value[2];
          
          switch (operator) {
            case '==':
              query = query.where(field, isEqualTo: filterValue);
              break;
            case '>':
              query = query.where(field, isGreaterThan: filterValue);
              break;
            case '>=':
              query = query.where(field, isGreaterThanOrEqualTo: filterValue);
              break;
            case '<':
              query = query.where(field, isLessThan: filterValue);
              break;
            case '<=':
              query = query.where(field, isLessThanOrEqualTo: filterValue);
              break;
            case 'array-contains':
              query = query.where(field, arrayContains: filterValue);
              break;
            case 'in':
              query = query.where(field, whereIn: filterValue as List<dynamic>);
              break;
            case 'array-contains-any':
              query = query.where(field, arrayContainsAny: filterValue as List<dynamic>);
              break;
          }
        } else {
          // Filtro simple de igualdad
          query = query.where(key, isEqualTo: value);
        }
      });
      
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => _fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        message: 'Error al realizar consulta: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error inesperado al realizar consulta: $e',
      );
    }
  }

  @override
  Future<void> save(T data) async {
    try {
      final id = _getId(data);
      final map = _toMap(data);
      
      await _firestore.collection(_collectionPath).doc(id).set(map);
    } on FirebaseException catch (e) {
      throw DatabaseException(
        message: 'Error al guardar documento: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error inesperado al guardar documento: $e',
      );
    }
  }

  @override
  Future<void> update({required String id, required Map<String, dynamic> data}) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).update(data);
    } on FirebaseException catch (e) {
      throw DatabaseException(
        message: 'Error al actualizar documento: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error inesperado al actualizar documento: $e',
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).delete();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        message: 'Error al eliminar documento: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error inesperado al eliminar documento: $e',
      );
    }
  }

  @override
  Future<bool> exists(String id) async {
    try {
      final docSnapshot = await _firestore.collection(_collectionPath).doc(id).get();
      return docSnapshot.exists;
    } on FirebaseException catch (e) {
      throw DatabaseException(
        message: 'Error al verificar existencia: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error inesperado al verificar existencia: $e',
      );
    }
  }

  @override
  Stream<T?> watchDocument(String id) {
    try {
      return _firestore.collection(_collectionPath).doc(id).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return _fromMap(doc.data()!);
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(
        message: 'Error al observar documento: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error inesperado al observar documento: $e',
      );
    }
  }

  @override
  Stream<List<T>> watchCollection({
    int? limit,
    String? orderBy,
    bool descending = false,
  }) {
    try {
      Query query = _firestore.collection(_collectionPath);
      
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .where((doc) => doc.data() != null)
            .map((doc) => _fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(
        message: 'Error al observar colección: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error inesperado al observar colección: $e',
      );
    }
  }

  @override
  Stream<List<T>> watchWhere({
    required String field,
    required dynamic isEqualTo,
    int? limit,
    String? orderBy,
    bool descending = false,
  }) {
    try {
      Query query = _firestore.collection(_collectionPath).where(field, isEqualTo: isEqualTo);
      
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .where((doc) => doc.data() != null)
            .map((doc) => _fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(
        message: 'Error al observar documentos con filtro: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error inesperado al observar documentos con filtro: $e',
      );
    }
  }

  @override
  Future<void> runTransaction(Future<void> Function(FirestoreTransactionHandler) action) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final handler = _FirestoreTransactionHandlerImpl(
          transaction: transaction,
          fromMap: _fromMap,
          typeKey: T.toString(),
        );
        await action(handler);
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(
        message: 'Error en transacción: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error inesperado en transacción: $e',
      );
    }
  }

  @override
  Future<void> runBatch(Future<void> Function(FirestoreBatchHandler) action) async {
    try {
      final batch = _firestore.batch();
      final handler = _FirestoreBatchHandlerImpl(
        batch: batch,
        firestore: _firestore,
      );
      await action(handler);
      await handler.commit();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        message: 'Error en operación por lotes: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error inesperado en operación por lotes: $e',
      );
    }
  }
}

/// Implementación del handler de transacciones de Firestore
class _FirestoreTransactionHandlerImpl implements FirestoreTransactionHandler {
  final Transaction transaction;
  final Map<String, dynamic Function(Map<String, dynamic>)> _fromMapFunctions = {};

  _FirestoreTransactionHandlerImpl({
    required this.transaction,
    required dynamic Function(Map<String, dynamic>) fromMap,
    required String typeKey,
  }) {
    // Registramos la función de mapeo con la clave de tipo proporcionada
    _fromMapFunctions[typeKey] = fromMap;
  }

  /// Registra una función de mapeo para un tipo específico
  void registerFromMapFunction<R>(R Function(Map<String, dynamic>) fromMap) {
    _fromMapFunctions[R.toString()] = (map) => fromMap(map);
  }

  @override
  Future<R?> get<R>(String collectionPath, String id) async {
    final docRef = FirebaseFirestore.instance.collection(collectionPath).doc(id);
    final docSnapshot = await transaction.get(docRef);
    
    if (!docSnapshot.exists || docSnapshot.data() == null) {
      return null;
    }
    
    final fromMapFunc = _fromMapFunctions[R.toString()];
    if (fromMapFunc == null) {
      throw DatabaseException(
        message: 'No se encontró una función de mapeo para el tipo $R',
      );
    }
    
    return fromMapFunc(docSnapshot.data()!) as R;
  }

  @override
  void set<R>(String collectionPath, String id, R data) {
    final docRef = FirebaseFirestore.instance.collection(collectionPath).doc(id);
    transaction.set(docRef, data as Map<String, dynamic>);
  }

  @override
  void update(String collectionPath, String id, Map<String, dynamic> data) {
    final docRef = FirebaseFirestore.instance.collection(collectionPath).doc(id);
    transaction.update(docRef, data);
  }

  @override
  void delete(String collectionPath, String id) {
    final docRef = FirebaseFirestore.instance.collection(collectionPath).doc(id);
    transaction.delete(docRef);
  }
}

/// Implementación del handler de operaciones por lotes de Firestore
class _FirestoreBatchHandlerImpl implements FirestoreBatchHandler {
  final WriteBatch batch;
  final FirebaseFirestore firestore;

  _FirestoreBatchHandlerImpl({
    required this.batch,
    required this.firestore,
  });

  @override
  void set<T>(String collectionPath, String id, T data) {
    final docRef = firestore.collection(collectionPath).doc(id);
    batch.set(docRef, data as Map<String, dynamic>);
  }

  @override
  void update(String collectionPath, String id, Map<String, dynamic> data) {
    final docRef = firestore.collection(collectionPath).doc(id);
    batch.update(docRef, data);
  }

  @override
  void delete(String collectionPath, String id) {
    final docRef = firestore.collection(collectionPath).doc(id);
    batch.delete(docRef);
  }

  @override
  Future<void> commit() async {
    await batch.commit();
  }
}
