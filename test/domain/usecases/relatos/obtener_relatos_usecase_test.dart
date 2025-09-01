import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/relatos/obtener_relatos_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/relato_repository.dart';
import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';

class _RelatoRepoListStub implements IRelatoRepository {
  final List<Relato> lista;
  _RelatoRepoListStub(this.lista);
  @override
  Future<List<Relato>> obtenerRelatos() async => lista;
  @override
  Future<List<Relato>> obtenerRelatosPorCategoria(String categoriaId) async => lista;
  @override
  Future<List<Relato>> obtenerRelatosPorAutor(String autorId) async => lista;
  @override
  Future<List<Relato>> obtenerRelatosPorUbicacion({String? departamento, String? municipio}) async => lista;
  @override
  Future<List<Relato>> obtenerRelatosCercanos({required double latitud, required double longitud, required double radioKm}) async => lista;
  @override
  Future<List<Relato>> buscarRelatos(String texto) async => lista;
  @override
  Stream<List<Relato>> observarRelatos() => Stream.value(lista);
  @override
  Stream<List<Relato>> observarRelatosPorCategoria(String categoriaId) => Stream.value(lista);
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Relato _relato() => Relato.crear(
  titulo: 'T', contenido: 'C', autorId: 'u', autorNombre: 'U', categoriaId: 'c', categoriaNombre: 'Cat',
);

void main() {
  group('ObtenerRelatosUseCase', () {
    test('execute retorna lista', () async {
      final repo = _RelatoRepoListStub([_relato()]);
      final usecase = ObtenerRelatosUseCase(repo);
      final result = await usecase.execute();
      expect(result.isSuccess, isTrue);
    });

    test('porCategoria retorna lista', () async {
      final repo = _RelatoRepoListStub([_relato()]);
      final usecase = ObtenerRelatosUseCase(repo);
      final result = await usecase.porCategoria('c');
      expect(result.isSuccess, isTrue);
    });

    test('porAutor retorna lista', () async {
      final repo = _RelatoRepoListStub([_relato()]);
      final usecase = ObtenerRelatosUseCase(repo);
      final result = await usecase.porAutor('u');
      expect(result.isSuccess, isTrue);
    });

    test('porUbicacion retorna lista', () async {
      final repo = _RelatoRepoListStub([_relato()]);
      final usecase = ObtenerRelatosUseCase(repo);
      final result = await usecase.porUbicacion(departamento: 'Managua');
      expect(result.isSuccess, isTrue);
    });

    test('cercanos retorna lista', () async {
      final repo = _RelatoRepoListStub([_relato()]);
      final usecase = ObtenerRelatosUseCase(repo);
      final result = await usecase.cercanos(latitud: 12.1, longitud: -86.2, radioKm: 5);
      expect(result.isSuccess, isTrue);
    });

    test('buscar retorna lista', () async {
      final repo = _RelatoRepoListStub([_relato()]);
      final usecase = ObtenerRelatosUseCase(repo);
      final result = await usecase.buscar('T');
      expect(result.isSuccess, isTrue);
    });

    test('observe emite lista', () async {
      final repo = _RelatoRepoListStub([_relato()]);
      final usecase = ObtenerRelatosUseCase(repo);
      final items = await usecase.observe().first;
      expect(items, isNotEmpty);
    });
  });
}
