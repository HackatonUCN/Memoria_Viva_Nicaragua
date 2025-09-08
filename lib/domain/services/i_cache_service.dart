/// Interfaz para el servicio de caché local con soporte TTL y LRU
abstract class ICacheService {
  /// Guarda un valor con clave [key].
  /// TTL en segundos opcional; si es null, no expira por tiempo.
  Future<void> set<T>(String key, T value, {int? ttlSeconds, String? tag});

  /// Obtiene un valor tipado; devuelve null si no existe o expiró.
  Future<T?> get<T>(String key);

  /// Elimina una clave específica.
  Future<void> invalidate(String key);

  /// Elimina por etiqueta (tag) para invalidación selectiva.
  Future<int> invalidateByTag(String tag);

  /// Limpia toda la caché.
  Future<void> clear();

  /// Configura el máximo de entradas en memoria (LRU eviction).
  void setMaxEntries(int maxEntries);

  /// Métricas básicas de la caché.
  Future<Map<String, dynamic>> stats();
}


