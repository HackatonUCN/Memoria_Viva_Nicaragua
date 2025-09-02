/// Interfaz para la fuente de datos de Firestore
/// T es el tipo de datos del modelo
abstract class FirestoreDataSource<T> {
  /// Colección principal en Firestore
  String get collectionPath;

  /// Obtiene un documento por su ID
  Future<T?> getById(String id);

  /// Obtiene todos los documentos de la colección
  Future<List<T>> getAll({
    int? limit,
    String? orderBy,
    bool descending = false,
  });

  /// Obtiene documentos filtrados por un campo específico
  Future<List<T>> getWhere({
    required String field,
    required dynamic isEqualTo,
    int? limit,
    String? orderBy,
    bool descending = false,
  });

  /// Obtiene documentos con filtros personalizados
  Future<List<T>> query({
    required Map<String, dynamic> filters,
    int? limit,
    String? orderBy,
    bool descending = false,
  });

  /// Guarda un documento (crea si no existe, actualiza si existe)
  Future<void> save(T data);

  /// Actualiza un documento específico
  Future<void> update({required String id, required Map<String, dynamic> data});

  /// Elimina un documento por su ID
  Future<void> delete(String id);

  /// Verifica si un documento existe
  Future<bool> exists(String id);

  /// Stream de cambios en un documento específico
  Stream<T?> watchDocument(String id);

  /// Stream de cambios en la colección completa
  Stream<List<T>> watchCollection({
    int? limit,
    String? orderBy,
    bool descending = false,
  });

  /// Stream de cambios en documentos filtrados
  Stream<List<T>> watchWhere({
    required String field,
    required dynamic isEqualTo,
    int? limit,
    String? orderBy,
    bool descending = false,
  });

  /// Ejecuta una transacción con varios documentos
  Future<void> runTransaction(
    Future<void> Function(FirestoreTransactionHandler) action);

  /// Ejecuta operaciones por lotes
  Future<void> runBatch(Future<void> Function(FirestoreBatchHandler) action);
}

/// Interfaz para manejar transacciones en Firestore
abstract class FirestoreTransactionHandler {
  /// Obtiene un documento en una transacción
  Future<T?> get<T>(String collectionPath, String id);

  /// Establece un documento en una transacción
  void set<T>(String collectionPath, String id, T data);

  /// Actualiza un documento en una transacción
  void update(String collectionPath, String id, Map<String, dynamic> data);

  /// Elimina un documento en una transacción
  void delete(String collectionPath, String id);
}

/// Interfaz para manejar operaciones por lotes en Firestore
abstract class FirestoreBatchHandler {
  /// Establece un documento en un lote
  void set<T>(String collectionPath, String id, T data);

  /// Actualiza un documento en un lote
  void update(String collectionPath, String id, Map<String, dynamic> data);

  /// Elimina un documento en un lote
  void delete(String collectionPath, String id);

  /// Confirma el lote
  Future<void> commit();
}
