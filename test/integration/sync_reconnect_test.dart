import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/relato_repository.dart';
import 'package:memoria_viva_nicaragua/data/repositories/offline_relato_repository.dart';
import 'package:memoria_viva_nicaragua/domain/services/i_sync_queue.dart';
import 'package:memoria_viva_nicaragua/data/infrastructure/services/sync_queue_impl.dart';

/// Test de integración simplificado de reconexión usando fake_cloud_firestore
class _RemoteRelatoRepoFake implements IRelatoRepository {
  final FakeFirebaseFirestore firestore;
  _RemoteRelatoRepoFake(this.firestore);

  @override
  Future<void> guardarRelato(Relato relato) async {
    await firestore.collection('relatos').doc(relato.id).set(relato.toMap());
  }

  // Métodos no usados en este test
  @override
  Future<void> actualizarRelato(Relato relato) async {}
  @override
  Future<void> eliminarRelato(String id) async {}
  @override
  Future<List<Relato>> obtenerRelatos() async => <Relato>[];
  @override
  Future<Relato?> obtenerRelatoPorId(String id) async => null;
  @override
  Future<List<Relato>> obtenerRelatosPorAutor(String autorId) async => <Relato>[];
  @override
  Future<List<Relato>> obtenerRelatosPorCategoria(String categoriaId) async => <Relato>[];
  @override
  Future<List<Relato>> obtenerRelatosPorUbicacion({String? departamento, String? municipio}) async => <Relato>[];
  @override
  Future<bool> reportarRelato(String id, String razon, {required String userId}) async => true;
  @override
  Future<void> restaurarRelato(String id) async {}
  @override
  Future<void> moderarRelato(String id, estado) async {}
  @override
  Future<bool> toggleLike({required String id, required String userId}) async => true;
  @override
  Future<void> registrarCompartido(String id) async {}
  @override
  Stream<List<Relato>> observarRelatos() => const Stream.empty();
  @override
  Stream<Relato?> observarRelatoPorId(String id) => const Stream.empty();
  @override
  Stream<List<Relato>> observarRelatosPorCategoria(String categoriaId) => const Stream.empty();
  @override
  Future<List<Relato>> buscarRelatos(String texto) async => <Relato>[];
  @override
  Future<List<Relato>> obtenerRelatosCercanos({required double latitud, required double longitud, required double radioKm}) async => <Relato>[];
  @override
  Future<List<Relato>> buscarRelatosSimilares({required String titulo, required String autorId}) async => <Relato>[];

  @override
  Future<List<Relato>> obtenerRelatosEnBounds({
    required double south,
    required double west,
    required double north,
    required double east,
    int limit = 200,
  }) async => <Relato>[];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Crea relato offline y sincroniza al reconectar (simulado)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = SyncQueueImpl(prefs);
    final fakeFs = FakeFirebaseFirestore();
    final remote = _RemoteRelatoRepoFailThenOk(fakeFs);
    final repo = OfflineRelatoRepository(remote, queue);

    // Simular fallo de red: guardar encola
    await repo.guardarRelato(Relato.crear(
      titulo: 't',
      contenido: 'c'.padRight(25, 'c'),
      autorId: 'u1',
      autorNombre: 'User',
      categoriaId: 'cat',
      categoriaNombre: 'Cat',
    ));
    expect(await queue.length(), 1);

    // Simular reconexión: procesar manualmente la cola
    final ops = await queue.peek(limit: 10);
    for (final op in ops) {
      await remote.guardarRelato(Relato.fromMap(op.payload));
      await queue.markDone(op.id);
    }
    expect(await queue.length(), 0);
    final snap = await fakeFs.collection('relatos').get();
    expect(snap.docs.length, 1);
  });
}

class _RemoteRelatoRepoFailThenOk extends _RemoteRelatoRepoFake {
  bool _first = true;
  _RemoteRelatoRepoFailThenOk(super.firestore);
  @override
  Future<void> guardarRelato(Relato relato) async {
    if (_first) {
      _first = false;
      throw Exception('network');
    }
    await super.guardarRelato(relato);
  }
}


