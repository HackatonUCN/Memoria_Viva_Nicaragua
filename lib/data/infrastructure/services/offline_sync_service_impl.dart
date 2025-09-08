import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../domain/entities/relato.dart';
import '../../../domain/entities/saber_popular.dart';
import '../../../domain/entities/evento_cultural.dart';
import '../../../domain/services/i_offline_sync_service.dart';
import '../../../domain/services/i_cache_service.dart';

/// Servicio de sincronización offline apoyado en Firestore Offline + caché local
class OfflineSyncServiceImpl implements IOfflineSyncService {
  final FirebaseFirestore _firestore;
  final ICacheService _cache;
  final StreamController<Map<String, dynamic>> _estadoCtrl = StreamController.broadcast();
  StreamSubscription? _connSub;
  bool _offline = false;

  OfflineSyncServiceImpl(this._firestore, this._cache);

  @override
  Future<void> inicializar() async {
    await activarModoOffline();
    // Observa conectividad
    _connSub = Connectivity().onConnectivityChanged.listen((status) {
      final online = status != ConnectivityResult.none;
      _offline = !online;
      _estadoCtrl.add({'online': online});
    });
  }

  @override
  Future<void> activarModoOffline() async {
    // Firestore Flutter habilita caché local por defecto en mobile/desktop.
    // En web, la persistencia se gestiona en el initialization de Firebase (no aquí).
    // Podemos ajustar settings básicos si se requiere en el futuro.
  }

  @override
  Future<void> desactivarModoOffline() async {
    // Firestore no permite deshabilitar en runtime; se puede limpiar caché si es necesario
  }

  @override
  bool estaEnModoOffline() => _offline;

  @override
  Future<bool> verificarConexion() async {
    final status = await Connectivity().checkConnectivity();
    return status != ConnectivityResult.none;
  }

  @override
  Future<void> configurarContenidoASincronizar(List<String> tiposContenido) async {
    await _cache.set('sync:tipos', tiposContenido, ttlSeconds: 86400);
  }

  @override
  Future<void> configurarLimiteAlmacenamiento(int limiteMB) async {
    await _cache.set('sync:limiteMB', limiteMB);
  }

  @override
  Future<double> obtenerEspacioUtilizado() async {
    // Estimar por número de entradas en caché; real: medir tamaño en disco usando Hive/SQLite
    final stats = await _cache.stats();
    return (stats['entries'] as int) * 0.01; // ~10KB por entrada (estimado)
  }

  @override
  Future<Map<String, dynamic>> sincronizarDatos() async {
    // En una implementación completa: subir colas locales pendientes y refrescar cachés críticas
    return {'status': 'ok'};
  }

  @override
  Future<void> guardarRelatoOffline(Relato relato) async {
    await _cache.set('pending:relato:${relato.id}', relato.toMap(), tag: 'pending:relato');
  }

  @override
  Future<void> guardarSaberOffline(SaberPopular saber) async {
    await _cache.set('pending:saber:${saber.id}', saber.toMap(), tag: 'pending:saber');
  }

  @override
  Future<void> guardarEventoOffline(EventoCultural evento) async {
    await _cache.set('pending:evento:${evento.id}', evento.toMap(), tag: 'pending:evento');
  }

  @override
  Future<void> guardarComentarioOffline({required String contenidoId, required String tipoContenido, required String texto}) async {
    await _cache.set('pending:comentario:$tipoContenido:$contenidoId', {'texto': texto});
  }

  @override
  Future<void> guardarInteraccionOffline({required String contenidoId, required String tipoContenido, required String tipoInteraccion}) async {
    await _cache.set('pending:interaccion:$tipoContenido:$contenidoId', {'tipo': tipoInteraccion});
  }

  @override
  Future<List<Relato>> obtenerRelatosOffline() async => [];

  @override
  Future<List<SaberPopular>> obtenerSaberesOffline() async => [];

  @override
  Future<List<EventoCultural>> obtenerEventosOffline() async => [];

  @override
  Future<Map<String, List<dynamic>>> obtenerContenidoPendiente() async {
    // Se requiere un backend de claves para enumerar; con Hive/SQLite sería directo.
    return {'relatos': [], 'saberes': [], 'eventos': []};
  }

  @override
  Future<void> eliminarContenidoLocal({required String contenidoId, required String tipoContenido}) async {
    await _cache.invalidate('pending:$tipoContenido:$contenidoId');
  }

  @override
  Future<void> limpiarContenidoLocal() async {
    await _cache.invalidateByTag('pending:relato');
    await _cache.invalidateByTag('pending:saber');
    await _cache.invalidateByTag('pending:evento');
  }

  @override
  Future<Map<String, int>> descargarContenido({List<String>? tiposContenido, String? departamento, String? municipio, int? limitePorTipo}) async {
    // Precarga de datos críticos: categorías, perfil; aquí se implementaría consulta y almacenamiento
    return {'categorias': 0, 'perfil': 0};
  }

  @override
  Future<void> configurarSincronizacionAutomatica({required bool activa, int? intervaloMinutos, bool? soloWifi}) async {
    await _cache.set('sync:auto', activa);
  }

  @override
  Future<Map<String, dynamic>> obtenerEstadoSincronizacion() async => {'online': !(estaEnModoOffline())};

  @override
  void registrarListenerSincronizacion(Function(Map<String, dynamic> p1) callback) {
    _estadoCtrl.stream.listen(callback);
  }

  @override
  void eliminarListenerSincronizacion(Function(Map<String, dynamic> p1) callback) {/* not tracked individually */}

  @override
  Future<void> resolverConflicto({required String contenidoId, required String tipoContenido, required bool usarVersionLocal}) async {}

  @override
  Future<List<Map<String, dynamic>>> verificarConflictosPendientes() async => [];

  @override
  Future<void> priorizarSincronizacion({required String contenidoId, required String tipoContenido}) async {}

  @override
  Future<void> cancelarSincronizacion() async {}
  @override
  Future<void> pausarSincronizacion() async {}
  @override
  Future<void> reanudarSincronizacion() async {}
}


