import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/relatos/moderar_relato_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/relato_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';
import 'package:memoria_viva_nicaragua/domain/enums/estado_moderacion.dart';

class _RelatoRepoStub implements IRelatoRepository {
  Relato? fuente;
  EstadoModeracion? ultimoEstado;
  _RelatoRepoStub(this.fuente);
  @override
  Future<Relato?> obtenerRelatoPorId(String id) async => fuente;
  @override
  Future<void> moderarRelato(String id, EstadoModeracion estado) async { ultimoEstado = estado; }
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserRepoStub implements IUserRepository {
  final User? user;
  _UserRepoStub(this.user);
  @override
  Future<User?> obtenerUsuarioPorId(String id) async => user;
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Relato _baseRelato({required String autorId}) => Relato.crear(
  titulo: 'Titulo', contenido: 'Contenido', autorId: autorId, autorNombre: 'Autor', categoriaId: 'c', categoriaNombre: 'Cat',
);

void main() {
  group('ModerarRelatoUseCase', () {
    test('admin modera a oculto', () async {
      final original = _baseRelato(autorId: 'autor');
      final repo = _RelatoRepoStub(original);
      final userRepo = _UserRepoStub(User.crear(id: 'a', nombre: 'Admin', email: 'a@a.com', rol: UserRole.admin));
      final usecase = ModerarRelatoUseCase(repo, userRepo);

      final result = await usecase.execute(adminId: 'a', relatoId: 'r1', estado: EstadoModeracion.oculto);
      expect(result.isSuccess, isTrue);
      expect(repo.ultimoEstado, EstadoModeracion.oculto);
    });

    test('falla si no es admin', () async {
      final original = _baseRelato(autorId: 'autor');
      final repo = _RelatoRepoStub(original);
      final userRepo = _UserRepoStub(User.crear(id: 'u', nombre: 'User', email: 'u@u.com', rol: UserRole.normal));
      final usecase = ModerarRelatoUseCase(repo, userRepo);

      final result = await usecase.execute(adminId: 'u', relatoId: 'r1', estado: EstadoModeracion.oculto);
      expect(result.isFailure, isTrue);
    });
  });
}
