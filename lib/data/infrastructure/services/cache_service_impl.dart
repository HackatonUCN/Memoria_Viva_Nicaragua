import 'dart:collection';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/services/i_cache_service.dart';

class CacheEntry<T> {
  final T value;
  final DateTime? expiresAt;
  final String? tag;
  DateTime lastAccess;
  CacheEntry({required this.value, this.expiresAt, this.tag, DateTime? lastAccess})
      : lastAccess = lastAccess ?? DateTime.now();
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Implementación híbrida de caché en memoria + SharedPreferences
/// - LRU en memoria con límite configurable
/// - TTL por clave
class CacheServiceImpl implements ICacheService {
  final SharedPreferences _prefs;
  final LinkedHashMap<String, CacheEntry<dynamic>> _memory = LinkedHashMap();
  int _maxEntries = 200;

  CacheServiceImpl(this._prefs);

  @override
  void setMaxEntries(int maxEntries) {
    _maxEntries = maxEntries < 1 ? 1 : (maxEntries > 2000 ? 2000 : maxEntries);
    _evictIfNeeded();
  }

  @override
  Future<void> set<T>(String key, T value, {int? ttlSeconds, String? tag}) async {
    final expiresAt = ttlSeconds != null ? DateTime.now().add(Duration(seconds: ttlSeconds)) : null;
    _touch(key, CacheEntry<T>(value: value, expiresAt: expiresAt, tag: tag));
    // Persistir metadatos mínimos para supervivencia de proceso
    await _prefs.setString('_meta:$key', _serializeMeta(expiresAt, tag));
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else {
      // Para objetos complejos, solo mantener en memoria (se puede extender a Hive/SQLite)
    }
    _evictIfNeeded();
  }

  @override
  Future<T?> get<T>(String key) async {
    final entry = _memory.remove(key);
    if (entry != null) {
      if (entry.isExpired) {
        await invalidate(key);
        return null;
      }
      // LRU: reinsertar al final como el más reciente
      entry.lastAccess = DateTime.now();
      _memory[key] = entry;
      return entry.value as T?;
    }
    // Intentar leer de disco para tipos primitivos
    final meta = _deserializeMeta(_prefs.getString('_meta:$key'));
    if (meta != null && meta['expiresAt'] != null && DateTime.now().isAfter(meta['expiresAt'])) {
      await invalidate(key);
      return null;
    }
    final Object? raw = _prefs.get(key);
    if (raw == null) return null;
    final cacheEntry = CacheEntry<dynamic>(value: raw, expiresAt: meta?['expiresAt'], tag: meta?['tag']);
    _touch(key, cacheEntry);
    return raw as T?;
  }

  @override
  Future<void> invalidate(String key) async {
    _memory.remove(key);
    await _prefs.remove(key);
    await _prefs.remove('_meta:$key');
  }

  @override
  Future<int> invalidateByTag(String tag) async {
    int count = 0;
    final keys = List<String>.from(_memory.keys);
    for (final k in keys) {
      final entry = _memory[k];
      if (entry?.tag == tag) {
        await invalidate(k);
        count++;
      }
    }
    // No intentamos persistentes por simplicidad
    return count;
  }

  @override
  Future<void> clear() async {
    _memory.clear();
    // Evitar borrar todo SharedPreferences; limpiar solo claves gestionadas si se quiere afinar.
  }

  @override
  Future<Map<String, dynamic>> stats() async => {
        'entries': _memory.length,
        'maxEntries': _maxEntries,
      };

  // ----- internals -----
  void _touch(String key, CacheEntry<dynamic> entry) {
    _memory.remove(key);
    entry.lastAccess = DateTime.now();
    _memory[key] = entry;
  }

  void _evictIfNeeded() {
    while (_memory.length > _maxEntries) {
      // Evict por LRU según lastAccess más antiguo
      String? oldestKey;
      DateTime? oldestTime;
      _memory.forEach((k, v) {
        if (oldestTime == null || v.lastAccess.isBefore(oldestTime!)) {
          oldestTime = v.lastAccess;
          oldestKey = k;
        }
      });
      if (oldestKey != null) {
        _memory.remove(oldestKey);
        // Remover persistencia asociada para que get() no reconstruya claves expulsadas
        _prefs.remove(oldestKey!);
        _prefs.remove('_meta:$oldestKey');
      } else {
        break;
      }
    }
  }

  String _serializeMeta(DateTime? expiresAt, String? tag) => [
        expiresAt?.millisecondsSinceEpoch?.toString() ?? '',
        tag ?? '',
      ].join('|');

  Map<String, dynamic>? _deserializeMeta(String? s) {
    if (s == null) return null;
    final parts = s.split('|');
    final ts = parts.isNotEmpty && parts[0].isNotEmpty ? int.tryParse(parts[0]) : null;
    return {
      'expiresAt': ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null,
      'tag': parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
    };
  }
}


