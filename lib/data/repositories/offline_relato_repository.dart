import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';
import 'package:memoria_viva_nicaragua/domain/enums/estado_moderacion.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/relato_repository.dart';

import '../../domain/services/i_sync_queue.dart';

/// Wrapper que agrega capacidades offline a IRelatoRepository
class OfflineRelatoRepository implements IRelatoRepository {
  final IRelatoRepository _remote;
  final ISyncQueue _queue;

  OfflineRelatoRepository(this._remote, this._queue);

  @override
  Future<void> actualizarRelato(Relato relato) async {
    try {
      await _remote.actualizarRelato(relato);
    } catch (_) {
      await _queue.enqueue(SyncOperation(
        id: 'relato:update:${relato.id}:${DateTime.now().microsecondsSinceEpoch}',
        resource: 'relato',
        resourceId: relato.id,
        type: SyncOperationType.update,
        payload: relato.toMap(),
        createdAt: DateTime.now().toUtc(),
        priority: 5,
      ));
    }
  }

  @override
  Future<void> eliminarRelato(String id) async {
    try {
      await _remote.eliminarRelato(id);
    } catch (_) {
      await _queue.enqueue(SyncOperation(
        id: 'relato:delete:$id:${DateTime.now().microsecondsSinceEpoch}',
        resource: 'relato',
        resourceId: id,
        type: SyncOperationType.delete,
        payload: {'id': id},
        createdAt: DateTime.now().toUtc(),
        priority: 10,
      ));
    }
  }

  @override
  Future<void> guardarRelato(Relato relato) async {
    final opId = 'relato:create:${relato.id}:${DateTime.now().microsecondsSinceEpoch}';
    await _queue.enqueue(SyncOperation(
      id: opId,
      resource: 'relato',
      resourceId: relato.id,
      type: SyncOperationType.create,
      payload: relato.toMap(),
      createdAt: DateTime.now().toUtc(),
      priority: 8,
    ));
    try {
      // Intento inmediato online
      // Si falla por permisos/reglas u otros errores, re-lanzamos para que la UI muestre el fallo real
      // Si falla por conectividad, quedará encolado y reintentará el SyncWorker
      // Logs mínimos para diagnóstico
      print('[OFFLINE_QUEUE][CREATE_ATTEMPT] resource=relato id=${relato.id} op=$opId');
      await _remote.guardarRelato(relato);
      await _queue.markDone(opId);
      print('[OFFLINE_QUEUE][SYNC_OK] resource=relato id=${relato.id} op=$opId');
    } catch (_) {
      // Dejar en cola y propagar el error para que la capa superior decida (p.ej., mostrar error o modo offline)
      print('[OFFLINE_QUEUE][SYNC_FAIL] resource=relato id=${relato.id} op=$opId (queda en cola)');
      rethrow;
    }
  }

  // Passthroughs (lecturas online/offline resueltas por Firestore cache)
  @override
  Future<List<Relato>> obtenerRelatos() => _remote.obtenerRelatos();
  @override
  Future<Relato?> obtenerRelatoPorId(String id) => _remote.obtenerRelatoPorId(id);
  @override
  Future<List<Relato>> obtenerRelatosPorCategoria(String categoriaId) => _remote.obtenerRelatosPorCategoria(categoriaId);
  @override
  Future<List<Relato>> obtenerRelatosPorAutor(String autorId) => _remote.obtenerRelatosPorAutor(autorId);
  @override
  Future<List<Relato>> obtenerRelatosPorUbicacion({String? departamento, String? municipio}) => _remote.obtenerRelatosPorUbicacion(departamento: departamento, municipio: municipio);
  @override
  Future<void> restaurarRelato(String id) => _remote.restaurarRelato(id);
  @override
  Future<void> reportarRelato(String id, String razon) => _remote.reportarRelato(id, razon);
  @override
  Future<void> moderarRelato(String id, EstadoModeracion estado) => _remote.moderarRelato(id, estado);
  @override
  Future<void> darLike(String id) => _remote.darLike(id);
  @override
  Future<void> registrarCompartido(String id) => _remote.registrarCompartido(id);
  @override
  Stream<List<Relato>> observarRelatos() => _remote.observarRelatos();
  @override
  Stream<Relato?> observarRelatoPorId(String id) => _remote.observarRelatoPorId(id);
  @override
  Stream<List<Relato>> observarRelatosPorCategoria(String categoriaId) => _remote.observarRelatosPorCategoria(categoriaId);
  @override
  Future<List<Relato>> buscarRelatos(String texto) => _remote.buscarRelatos(texto);
  @override
  Future<List<Relato>> obtenerRelatosCercanos({required double latitud, required double longitud, required double radioKm}) => _remote.obtenerRelatosCercanos(latitud: latitud, longitud: longitud, radioKm: radioKm);
  @override
  Future<List<Relato>> buscarRelatosSimilares({required String titulo, required String autorId}) => _remote.buscarRelatosSimilares(titulo: titulo, autorId: autorId);
}


