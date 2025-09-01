import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/saberes/reportar_saber_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/saber_popular_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/entities/saber_popular.dart';
import 'package:memoria_viva_nicaragua/domain/enums/estado_moderacion.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';

class _SaberRepoStub implements ISaberPopularRepository {
  SaberPopular? fuente;
  SaberPopular? actualizado;
  _SaberRepoStub(this.fuente);
  @override
  Future<SaberPopular?> obtenerSaberPorId(String id) async => fuente;
  @override
  Future<void> actualizarSaber(SaberPopular saber) async { actualizado = saber; }
  @override
  Future<void> moderarSaber(String id, EstadoModeracion estado) async {}
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserRepoStub implements IUserRepository {
  final User? user;
  _UserRepoStub(this.user);
  @override
  Future<User?> obtenerUsuarioPorId(String id) async => user;
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SaberPopular _saber({required String autorId}) => SaberPopular.crear(
  titulo: 'T', contenido: 'C', autorId: autorId, autorNombre: 'Autor', categoriaId: 'c', categoriaNombre: 'Cat',
);

void main() {
  group('ReportarSaberUseCase', () {
    test('reporta saber con éxito', () async {
      final repo = _SaberRepoStub(_saber(autorId: 'autor'));
      final userRepo = _UserRepoStub(User.crear(id: 'u1', nombre: 'U', email: 'u@u.com'));
      final usecase = ReportarSaberUseCase(repo, userRepo);

      final result = await usecase.execute(usuarioId: 'u1', saberId: 's1', razon: 'spam');
      expect(result.isSuccess, isTrue);
      expect(repo.actualizado, isNotNull);
    });

    test('falla si intenta reportar propio', () async {
      final repo = _SaberRepoStub(_saber(autorId: 'u1'));
      final userRepo = _UserRepoStub(User.crear(id: 'u1', nombre: 'U', email: 'u@u.com'));
      final usecase = ReportarSaberUseCase(repo, userRepo);

      final result = await usecase.execute(usuarioId: 'u1', saberId: 's1', razon: 'spam');
      expect(result.isFailure, isTrue);
    });
  });
}
