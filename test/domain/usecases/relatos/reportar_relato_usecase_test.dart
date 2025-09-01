import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/relatos/reportar_relato_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/relato_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';

class _RelatoRepoStub implements IRelatoRepository {
  Relato? fuente;
  bool reportado = false;
  _RelatoRepoStub(this.fuente);
  @override
  Future<Relato?> obtenerRelatoPorId(String id) async => fuente;
  @override
  Future<void> reportarRelato(String id, String razon) async { reportado = true; }
  @override
  Future<void> moderarRelato(String id, dynamic estado) async {}
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserRepoStub implements IUserRepository {
  final User? user;
  _UserRepoStub(this.user);
  @override
  Future<User?> obtenerUsuarioPorId(String id) async => user;
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Relato _relato() => Relato.crear(
  titulo: 'T', contenido: 'C', autorId: 'autor', autorNombre: 'Autor', categoriaId: 'c', categoriaNombre: 'Cat',
);

void main() {
  group('ReportarRelatoUseCase', () {
    test('reporta relato con éxito', () async {
      final repo = _RelatoRepoStub(_relato());
      final userRepo = _UserRepoStub(User.crear(id: 'u1', nombre: 'U', email: 'u@u.com'));
      final usecase = ReportarRelatoUseCase(repo, userRepo);

      final result = await usecase.execute(usuarioId: 'u1', relatoId: 'r1', razon: 'spam');
      expect(result.isSuccess, isTrue);
      expect(repo.reportado, isTrue);
    });

    test('falla si relato no existe', () async {
      final repo = _RelatoRepoStub(null);
      final userRepo = _UserRepoStub(User.crear(id: 'u1', nombre: 'U', email: 'u@u.com'));
      final usecase = ReportarRelatoUseCase(repo, userRepo);

      final result = await usecase.execute(usuarioId: 'u1', relatoId: 'r1', razon: 'spam');
      expect(result.isFailure, isTrue);
    });
  });
}
