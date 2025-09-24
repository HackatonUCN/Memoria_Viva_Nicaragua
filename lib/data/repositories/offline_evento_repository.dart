import 'package:memoria_viva_nicaragua/domain/entities/evento_cultural.dart';
import 'package:memoria_viva_nicaragua/domain/enums/tipos_evento.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/evento_cultural_repository.dart';

import '../../domain/services/i_sync_queue.dart';
import '../../domain/services/i_cache_service.dart';

/// Wrapper offline para IEventoCulturalRepository (server-wins por defecto)
class OfflineEventoRepository implements IEventoCulturalRepository {
  final IEventoCulturalRepository _remote;
  final ISyncQueue _queue;
  final ICacheService? _cacheService;
  // Cache en memoria con TTL simple
  final Map<String, _CacheEntry<List<EventoCultural>>> _cache = <String, _CacheEntry<List<EventoCultural>>>{};
  Duration cacheTtl = const Duration(minutes: 3);

  OfflineEventoRepository(this._remote, this._queue, [this._cacheService]);

  @override
  Future<void> actualizarEvento(EventoCultural evento) async {
    try {
      await _remote.actualizarEvento(evento);
      try { await _cacheService?.invalidateByTag('eventos'); } catch (_) {}
    } catch (_) {
      await _queue.enqueue(SyncOperation(
        id: 'evento:update:${evento.id}:${DateTime.now().microsecondsSinceEpoch}',
        resource: 'evento',
        resourceId: evento.id,
        type: SyncOperationType.update,
        payload: evento.toMap(),
        createdAt: DateTime.now().toUtc(),
        priority: 4,
      ));
    }
  }

  @override
  Future<void> eliminarEvento(String id) async {
    try {
      await _remote.eliminarEvento(id);
      try { await _cacheService?.invalidateByTag('eventos'); } catch (_) {}
    } catch (_) {
      await _queue.enqueue(SyncOperation(
        id: 'evento:delete:$id:${DateTime.now().microsecondsSinceEpoch}',
        resource: 'evento',
        resourceId: id,
        type: SyncOperationType.delete,
        payload: {'id': id},
        createdAt: DateTime.now().toUtc(),
        priority: 9,
      ));
    }
  }

  @override
  Future<void> guardarEvento(EventoCultural evento) async {
    try {
      await _remote.guardarEvento(evento);
      try { await _cacheService?.invalidateByTag('eventos'); } catch (_) {}
    } catch (_) {
      await _queue.enqueue(SyncOperation(
        id: 'evento:create:${evento.id}:${DateTime.now().microsecondsSinceEpoch}',
        resource: 'evento',
        resourceId: evento.id,
        type: SyncOperationType.create,
        payload: evento.toMap(),
        createdAt: DateTime.now().toUtc(),
        priority: 5,
      ));
    }
  }

  @override
  Future<void> restaurarEvento(String id) async {
    try {
      await _remote.restaurarEvento(id);
      try { await _cacheService?.invalidateByTag('eventos'); } catch (_) {}
    } catch (_) {
      await _queue.enqueue(SyncOperation(
        id: 'evento:restore:$id:${DateTime.now().microsecondsSinceEpoch}',
        resource: 'evento',
        resourceId: id,
        type: SyncOperationType.update,
        payload: {'id': id, 'restore': true},
        createdAt: DateTime.now().toUtc(),
        priority: 6,
      ));
    }
  }

  // Passthroughs
  @override
  Future<List<EventoCultural>> obtenerEventos() => _remote.obtenerEventos();
  @override
  Future<EventoCultural?> obtenerEventoPorId(String id) => _remote.obtenerEventoPorId(id);
  @override
  Future<List<EventoCultural>> obtenerEventosPorCategoria(String categoriaId) async {
    final String key = 'cat:' + categoriaId;
    final entry = _cache[key];
    if (entry != null && entry.isFresh(_ttlForKey(key))) {
      return entry.value;
    }
    // Intentar desde cache service (memoria persistente del proceso)
    try {
      final cached = await _cacheService?.get<List<EventoCultural>>(key);
      if (cached != null) {
        _cache[key] = _CacheEntry<List<EventoCultural>>(cached);
        return cached;
      }
    } catch (_) {}
    final data = await _remote.obtenerEventosPorCategoria(categoriaId);
    _cache[key] = _CacheEntry<List<EventoCultural>>(data);
    try { await _cacheService?.set<List<EventoCultural>>(key, data, ttlSeconds: _ttlForKey(key).inSeconds, tag: 'eventos'); } catch (_) {}
    return data;
  }
  @override
  Future<List<EventoCultural>> obtenerEventosPorTipo(TipoEvento tipo) => _remote.obtenerEventosPorTipo(tipo);
  @override
  Future<List<EventoCultural>> obtenerEventosPorFecha(DateTime fecha) => _remote.obtenerEventosPorFecha(fecha);
  @override
  Future<List<EventoCultural>> obtenerEventosPorRangoFecha({required DateTime inicio, required DateTime fin}) async {
    final String key = 'range:' + inicio.millisecondsSinceEpoch.toString() + ':' + fin.millisecondsSinceEpoch.toString();
    final entry = _cache[key];
    if (entry != null && entry.isFresh(_ttlForKey(key))) {
      return entry.value;
    }
    try {
      final cached = await _cacheService?.get<List<EventoCultural>>(key);
      if (cached != null) {
        _cache[key] = _CacheEntry<List<EventoCultural>>(cached);
        return cached;
      }
    } catch (_) {}
    final data = await _remote.obtenerEventosPorRangoFecha(inicio: inicio, fin: fin);
    _cache[key] = _CacheEntry<List<EventoCultural>>(data);
    try { await _cacheService?.set<List<EventoCultural>>(key, data, ttlSeconds: _ttlForKey(key).inSeconds, tag: 'eventos'); } catch (_) {}
    return data;
  }
  @override
  Future<List<EventoCultural>> obtenerEventosPorUbicacion({String? departamento, String? municipio}) => _remote.obtenerEventosPorUbicacion(departamento: departamento, municipio: municipio);
  @override
  Stream<List<EventoCultural>> observarEventos() => _remote.observarEventos();
  @override
  Stream<EventoCultural?> observarEventoPorId(String id) => _remote.observarEventoPorId(id);
  @override
  Stream<List<EventoCultural>> observarEventosPorCategoria(String categoriaId) => _remote.observarEventosPorCategoria(categoriaId);
  @override
  Future<List<EventoCultural>> buscarEventos(String texto) => _remote.buscarEventos(texto);
  @override
  Future<List<EventoCultural>> obtenerEventosCercanos({required double latitud, required double longitud, required double radioKm}) => _remote.obtenerEventosCercanos(latitud: latitud, longitud: longitud, radioKm: radioKm);
  @override
  Future<List<SugerenciaEvento>> obtenerSugerenciasPendientes() => _remote.obtenerSugerenciasPendientes();
  @override
  Future<List<SugerenciaEvento>> obtenerSugerenciasPorUsuario(String usuarioId) => _remote.obtenerSugerenciasPorUsuario(usuarioId);
  @override
  Future<SugerenciaEvento?> obtenerSugerenciaPorId(String id) => _remote.obtenerSugerenciaPorId(id);
  @override
  Future<void> guardarSugerencia(SugerenciaEvento sugerencia) => _remote.guardarSugerencia(sugerencia);
  @override
  Future<void> aprobarSugerencia({required String sugerenciaId, required String adminId}) => _remote.aprobarSugerencia(sugerenciaId: sugerenciaId, adminId: adminId);
  @override
  Future<void> rechazarSugerencia({required String sugerenciaId, required String razon, required String adminId}) => _remote.rechazarSugerencia(sugerenciaId: sugerenciaId, razon: razon, adminId: adminId);
  @override
  Stream<List<SugerenciaEvento>> observarSugerenciasPendientes() => _remote.observarSugerenciasPendientes();
  @override
  Stream<List<SugerenciaEvento>> observarSugerenciasPorUsuario(String usuarioId) => _remote.observarSugerenciasPorUsuario(usuarioId);
}

class _CacheEntry<T> {
  final T value;
  final DateTime at;
  _CacheEntry(this.value) : at = DateTime.now();
  bool isFresh(Duration ttl) => DateTime.now().difference(at) < ttl;
}

extension on OfflineEventoRepository {
  // TTL por tipo de clave: carrusel (categoría) más corto; rango un poco más largo
  Duration _ttlForKey(String key) {
    if (key.startsWith('cat:')) return const Duration(seconds: 90);
    if (key.startsWith('range:')) return const Duration(seconds: 180);
    return cacheTtl;
  }
}


