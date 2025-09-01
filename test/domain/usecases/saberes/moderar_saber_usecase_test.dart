import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/saberes/moderar_saber_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/saber_popular_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/entities/saber_popular.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';

class _SaberRepoStub implements ISaberPopularRepository {
  SaberPopular? fuente;
  SaberPopular? actualizado;
  _SaberRepoStub(this.fuente);
  @override
  Future<SaberPopular?> obtenerSaberPorId(String id) async => fuente;
  @override
  Future<void> actualizarSaber(SaberPopular saber) async { actualizado = saber; }
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserRepoStub implements IUserRepository {
  final User? user;
  _UserRepoStub(this.user);
  @override
  Future<User?> obtenerUsuarioPorId(String id) async => user;
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SaberPopular _baseSaber({required String autorId}) => SaberPopular.crear(
  titulo: 'Titulo', contenido: 'Contenido', autorId: autorId, autorNombre: 'Autor', categoriaId: 'c', categoriaNombre: 'Cat',
);

void main() {
  group('ModerarSaberUseCase', () {
    test('admin modera (aprobar=true)', () async {
      final fuente = _baseSaber(autorId: 'autor');
      final repo = _SaberRepoStub(fuente);
      final userRepo = _UserRepoStub(User.crear(id: 'a', nombre: 'Admin', email: 'a@a.com', rol: UserRole.admin));
      final usecase = ModerarSaberUseCase(repo, userRepo);

      final result = await usecase.execute(adminId: 'a', saberId: 's1', aprobar: true);
      expect(result.isSuccess, isTrue);
      expect(repo.actualizado, isNotNull);
    });

    test('falla si no es admin', () async {
      final fuente = _baseSaber(autorId: 'autor');
      final repo = _SaberRepoStub(fuente);
      final userRepo = _UserRepoStub(User.crear(id: 'u', nombre: 'User', email: 'u@u.com', rol: UserRole.normal));
      final usecase = ModerarSaberUseCase(repo, userRepo);

      final result = await usecase.execute(adminId: 'u', saberId: 's1', aprobar: false, razon: 'spam');
      expect(result.isFailure, isTrue);
    });
  });
}
