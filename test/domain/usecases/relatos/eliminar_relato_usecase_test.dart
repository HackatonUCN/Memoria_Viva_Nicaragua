import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/relatos/eliminar_relato_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/relato_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';

class _RelatoRepoStub implements IRelatoRepository {
  Relato? fuente;
  bool eliminado = false;
  _RelatoRepoStub(this.fuente);
  @override
  Future<Relato?> obtenerRelatoPorId(String id) async => fuente;
  @override
  Future<void> eliminarRelato(String id) async { eliminado = true; }
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

Relato _baseRelato({required String autorId}) => Relato.crear(
  titulo: 'Titulo', contenido: 'Contenido', autorId: autorId, autorNombre: 'Autor', categoriaId: 'c', categoriaNombre: 'Cat',
);

void main() {
  group('EliminarRelatoUseCase', () {
    test('autor elimina relato (soft delete)', () async {
      final original = _baseRelato(autorId: 'u1');
      final repo = _RelatoRepoStub(original);
      final userRepo = _UserRepoStub(User.crear(id: 'u1', nombre: 'U', email: 'u@u.com', rol: UserRole.normal));
      final usecase = EliminarRelatoUseCase(repo, userRepo);

      final result = await usecase.execute(usuarioId: 'u1', relatoId: 'r1');
      expect(result.isSuccess, isTrue);
      expect(repo.eliminado, isTrue);
    });

    test('falla sin permisos (otro usuario)', () async {
      final original = _baseRelato(autorId: 'autor');
      final repo = _RelatoRepoStub(original);
      final userRepo = _UserRepoStub(User.crear(id: 'u2', nombre: 'Otro', email: 'o@o.com', rol: UserRole.normal));
      final usecase = EliminarRelatoUseCase(repo, userRepo);

      final result = await usecase.execute(usuarioId: 'u2', relatoId: 'r1');
      expect(result.isFailure, isTrue);
    });
  });
}
