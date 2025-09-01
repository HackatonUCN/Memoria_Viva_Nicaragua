import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/saberes/eliminar_saber_usecase.dart';
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
  @override
  Future<void> actualizarEstadisticas({required String userId, int? relatosPublicados, int? saberesCompartidos, int? puntajeTotal}) async {}
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SaberPopular _baseSaber({required String autorId}) => SaberPopular.crear(
  titulo: 'Titulo', contenido: 'Contenido', autorId: autorId, autorNombre: 'Autor', categoriaId: 'c', categoriaNombre: 'Cat',
);

void main() {
  group('EliminarSaberUseCase', () {
    test('autor elimina saber (soft delete)', () async {
      final fuente = _baseSaber(autorId: 'u1');
      final repo = _SaberRepoStub(fuente);
      final userRepo = _UserRepoStub(User.crear(id: 'u1', nombre: 'U', email: 'u@u.com', rol: UserRole.normal));
      final usecase = EliminarSaberUseCase(repo, userRepo);

      final result = await usecase.execute(usuarioId: 'u1', saberId: 's1');
      expect(result.isSuccess, isTrue);
      expect(repo.actualizado?.eliminado, isTrue);
    });

    test('falla sin permisos (otro usuario)', () async {
      final fuente = _baseSaber(autorId: 'autor');
      final repo = _SaberRepoStub(fuente);
      final userRepo = _UserRepoStub(User.crear(id: 'u2', nombre: 'Otro', email: 'o@o.com', rol: UserRole.normal));
      final usecase = EliminarSaberUseCase(repo, userRepo);

      final result = await usecase.execute(usuarioId: 'u2', saberId: 's1');
      expect(result.isFailure, isTrue);
    });
  });
}
