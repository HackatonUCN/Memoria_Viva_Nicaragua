import 'package:memoria_viva_nicaragua/domain/entities/saber_popular.dart';
import 'package:memoria_viva_nicaragua/domain/enums/estado_moderacion.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/saber_popular_repository.dart';

import '../../domain/services/i_sync_queue.dart';

/// Wrapper offline para ISaberPopularRepository (client-wins en create/update)
class OfflineSaberRepository implements ISaberPopularRepository {
  final ISaberPopularRepository _remote;
  final ISyncQueue _queue;

  OfflineSaberRepository(this._remote, this._queue);

  @override
  Future<void> actualizarSaber(SaberPopular saber) async {
    try {
      await _remote.actualizarSaber(saber);
    } catch (_) {
      await _queue.enqueue(SyncOperation(
        id: 'saber:update:${saber.id}:${DateTime.now().microsecondsSinceEpoch}',
        resource: 'saber',
        resourceId: saber.id,
        type: SyncOperationType.update,
        payload: saber.toMap(),
        createdAt: DateTime.now().toUtc(),
        priority: 6,
      ));
    }
  }

  @override
  Future<void> eliminarSaber(String id) async {
    try {
      await _remote.eliminarSaber(id);
    } catch (_) {
      await _queue.enqueue(SyncOperation(
        id: 'saber:delete:$id:${DateTime.now().microsecondsSinceEpoch}',
        resource: 'saber',
        resourceId: id,
        type: SyncOperationType.delete,
        payload: {'id': id},
        createdAt: DateTime.now().toUtc(),
        priority: 10,
      ));
    }
  }

  @override
  Future<void> guardarSaber(SaberPopular saber) async {
    try {
      await _remote.guardarSaber(saber);
    } catch (_) {
      await _queue.enqueue(SyncOperation(
        id: 'saber:create:${saber.id}:${DateTime.now().microsecondsSinceEpoch}',
        resource: 'saber',
        resourceId: saber.id,
        type: SyncOperationType.create,
        payload: saber.toMap(),
        createdAt: DateTime.now().toUtc(),
        priority: 7,
      ));
    }
  }

  // Passthroughs
  @override
  Future<List<SaberPopular>> obtenerSaberes() => _remote.obtenerSaberes();
  @override
  Future<SaberPopular?> obtenerSaberPorId(String id) => _remote.obtenerSaberPorId(id);
  @override
  Future<List<SaberPopular>> obtenerSaberesPorCategoria(String categoriaId) => _remote.obtenerSaberesPorCategoria(categoriaId);
  @override
  Future<List<SaberPopular>> obtenerSaberesPorAutor(String autorId) => _remote.obtenerSaberesPorAutor(autorId);
  @override
  Future<List<SaberPopular>> obtenerSaberesPorUbicacion({String? departamento, String? municipio}) => _remote.obtenerSaberesPorUbicacion(departamento: departamento, municipio: municipio);
  @override
  Future<void> restaurarSaber(String id) => _remote.restaurarSaber(id);
  @override
  Future<void> reportarSaber(String id, String razon) => _remote.reportarSaber(id, razon);
  @override
  Future<void> moderarSaber(String id, EstadoModeracion estado) => _remote.moderarSaber(id, estado);
  @override
  Future<void> darLike(String id) => _remote.darLike(id);
  @override
  Future<void> registrarCompartido(String id) => _remote.registrarCompartido(id);
  @override
  Stream<List<SaberPopular>> observarSaberes() => _remote.observarSaberes();
  @override
  Stream<SaberPopular?> observarSaberPorId(String id) => _remote.observarSaberPorId(id);
  @override
  Stream<List<SaberPopular>> observarSaberesPorCategoria(String categoriaId) => _remote.observarSaberesPorCategoria(categoriaId);
  @override
  Future<List<SaberPopular>> buscarSaberes(String texto) => _remote.buscarSaberes(texto);
  @override
  Future<List<SaberPopular>> buscarSaberesSimilares({required String titulo, required String categoriaId}) => _remote.buscarSaberesSimilares(titulo: titulo, categoriaId: categoriaId);
}


