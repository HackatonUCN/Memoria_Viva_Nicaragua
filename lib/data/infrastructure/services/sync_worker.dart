import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../domain/services/i_sync_queue.dart';
import '../../../domain/repositories/relato_repository.dart';
import '../../../domain/repositories/saber_popular_repository.dart';
import '../../../domain/repositories/evento_cultural_repository.dart';
import '../../../domain/entities/relato.dart';
import '../../../domain/entities/saber_popular.dart';
import '../../../domain/entities/evento_cultural.dart';

/// Worker que procesa la cola de sincronización cuando hay conectividad
class SyncWorker {
  final ISyncQueue _queue;
  final IRelatoRepository _relatos;
  final ISaberPopularRepository _saberes;
  final IEventoCulturalRepository _eventos;
  StreamSubscription? _connSub;
  bool _running = false;

  SyncWorker(this._queue, this._relatos, this._saberes, this._eventos);

  void start() {
    if (_running) return;
    _running = true;
    _connSub = Connectivity().onConnectivityChanged.listen((status) async {
      if (status != ConnectivityResult.none) {
        await _processQueue();
      }
    });
  }

  Future<void> _processQueue() async {
    final ops = await _queue.peek(limit: 20);
    for (final op in ops) {
      try {
        switch (op.resource) {
          case 'relato':
            await _dispatchRelato(op);
            break;
          case 'saber':
            await _dispatchSaber(op);
            break;
          case 'evento':
            await _dispatchEvento(op);
            break;
          default:
            break;
        }
        await _queue.markDone(op.id);
      } catch (_) {
        await _queue.markFailed(op.id);
      }
    }
  }

  // Estrategias simples:
  // - Client wins en create/update de contenido del usuario (relatos, saberes)
  // - Server wins en delete (si ya fue borrado en servidor, OK)
  Future<void> _dispatchRelato(SyncOperation op) async {
    if (op.type == SyncOperationType.create) {
      final relato = Relato.fromMap(op.payload);
      await _relatos.guardarRelato(relato);
      return;
    }
    if (op.type == SyncOperationType.update) {
      final relato = Relato.fromMap(op.payload);
      await _relatos.actualizarRelato(relato);
      return;
    }
    if (op.type == SyncOperationType.delete) {
      await _relatos.eliminarRelato(op.resourceId);
    }
  }

  Future<void> _dispatchSaber(SyncOperation op) async {
    if (op.type == SyncOperationType.create) {
      final saber = SaberPopular.fromMap(op.payload);
      await _saberes.guardarSaber(saber);
      return;
    }
    if (op.type == SyncOperationType.update) {
      final saber = SaberPopular.fromMap(op.payload);
      await _saberes.actualizarSaber(saber);
      return;
    }
    if (op.type == SyncOperationType.delete) {
      await _saberes.eliminarSaber(op.resourceId);
    }
  }

  Future<void> _dispatchEvento(SyncOperation op) async {
    // Server wins: simplemente reintenta la operación; opcionalmente verificar existencia remota
    if (op.type == SyncOperationType.create) {
      final evento = EventoCultural.fromMap(op.payload);
      await _eventos.guardarEvento(evento);
      return;
    }
    if (op.type == SyncOperationType.update) {
      final evento = EventoCultural.fromMap(op.payload);
      await _eventos.actualizarEvento(evento);
      return;
    }
    if (op.type == SyncOperationType.delete) {
      await _eventos.eliminarEvento(op.resourceId);
    }
  }

  Future<void> dispose() async {
    await _connSub?.cancel();
    _running = false;
  }
}


