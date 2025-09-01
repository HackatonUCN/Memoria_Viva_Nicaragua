import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/saberes/obtener_saberes_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/saber_popular_repository.dart';
import 'package:memoria_viva_nicaragua/domain/entities/saber_popular.dart';

class _SaberRepoListStub implements ISaberPopularRepository {
  final List<SaberPopular> lista;
  _SaberRepoListStub(this.lista);

  @override
  Future<List<SaberPopular>> obtenerSaberes() async => lista;

  @override
  Future<List<SaberPopular>> obtenerSaberesPorCategoria(String categoriaId) async => lista;

  @override
  Future<List<SaberPopular>> obtenerSaberesPorAutor(String autorId) async => lista;

  @override
  Future<List<SaberPopular>> obtenerSaberesPorUbicacion({String? departamento, String? municipio}) async => lista;

  @override
  Future<List<SaberPopular>> buscarSaberes(String texto) async => lista;

  @override
  Stream<List<SaberPopular>> observarSaberes() => Stream.value(lista);

  @override
  Stream<List<SaberPopular>> observarSaberesPorCategoria(String categoriaId) => Stream.value(lista);

  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SaberPopular _saber() => SaberPopular.crear(
  titulo: 'T', contenido: 'C', autorId: 'u', autorNombre: 'U', categoriaId: 'c', categoriaNombre: 'Cat',
);

void main() {
  group('ObtenerSaberesUseCase', () {
    test('execute retorna lista', () async {
      final repo = _SaberRepoListStub([_saber()]);
      final usecase = ObtenerSaberesUseCase(repo);
      final result = await usecase.execute();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNotEmpty);
    });

    test('observe emite lista', () async {
      final repo = _SaberRepoListStub([_saber()]);
      final usecase = ObtenerSaberesUseCase(repo);
      final items = await usecase.observe().first;
      expect(items, isNotEmpty);
    });
  });
}
